// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

//! A cache for the active committee and the price computation, that refreshed them periodically
//! when needed.

use std::{
    sync::Arc,
    time::{Duration, Instant},
};

use anyhow::Result;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_with::{serde_as, DurationSeconds};
use tokio::sync::{mpsc, oneshot, Notify};
use walrus_sui::{client::ReadClient, types::move_structs::EpochState};

use crate::{client::resource::PriceComputation, common::active_committees::ActiveCommittees};

pub(crate) type CommitteesRequestChannel =
    oneshot::Sender<(Arc<ActiveCommittees>, PriceComputation)>;

/// The configuration for the committees refresher.
#[serde_as]
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(default)]
pub struct CommitteesRefreshConfig {
    /// The interval after a new refresh can be requested by the client.
    ///
    /// If multiple refreshes are issued within `REFRESH_GRACE_PERIOD` of each other, only the first
    /// one is executed.
    #[serde(rename = "refresh_grace_period_secs")]
    #[serde_as(as = "DurationSeconds")]
    pub refresh_grace_period: Duration,
    /// The maximum interval after which the cache is force-refreshed automatically.
    #[serde(rename = "max_auto_refresh_interval_secs")]
    #[serde_as(as = "DurationSeconds")]
    pub max_auto_refresh_interval: Duration,
    /// The minimum interval after which the cache is force-refreshed automatically.
    #[serde(rename = "min_auto_refresh_interval_secs")]
    #[serde_as(as = "DurationSeconds")]
    pub min_auto_refresh_interval: Duration,
    /// A threshold of time from the expected epoch change, after which the auto-refresh interval
    /// switches from max to min.
    #[serde(rename = "epoch_change_distance_threshold_secs")]
    #[serde_as(as = "DurationSeconds")]
    pub epoch_change_distance_threshold: Duration,
    /// The size of the refresher channel.
    pub refresher_channel_size: usize,
}

impl CommitteesRefreshConfig {
    /// Builds a new [`CommitteesRefresher`] and [`CommitteesRefresherHandle`].
    pub async fn build_refresher_and_handle(
        &self,
        sui_client: impl ReadClient,
    ) -> Result<(
        CommitteesRefresher<impl ReadClient>,
        CommitteesRefresherHandle,
    )> {
        let notify = Arc::new(Notify::new());
        let (req_tx, req_rx) = mpsc::channel(self.refresher_channel_size);

        let refresher =
            CommitteesRefresher::new(self.clone(), sui_client, req_rx, notify.clone()).await?;

        Ok((refresher, CommitteesRefresherHandle::new(notify, req_tx)))
    }

    /// Builds a new [`CommitteesRefresher`], spawns it on a separate task, and
    /// returns the [`CommitteesRefresherHandle`].
    pub async fn build_refresher_and_run(
        &self,
        sui_client: impl ReadClient + 'static,
    ) -> Result<CommitteesRefresherHandle> {
        let (mut refresher, handle) = self.build_refresher_and_handle(sui_client).await?;

        tokio::spawn(async move {
            refresher.run().await;
        });

        Ok(handle)
    }
}

impl Default for CommitteesRefreshConfig {
    fn default() -> Self {
        Self {
            refresh_grace_period: default::REFRESH_GRACE_PERIOD,
            max_auto_refresh_interval: default::MAX_AUTO_REFRESH_INTERVAL,
            min_auto_refresh_interval: default::MIN_AUTO_REFRESH_INTERVAL,
            epoch_change_distance_threshold: default::EPOCH_CHANGE_DISTANCE_THRS,
            refresher_channel_size: default::REFRESHER_CHANNEL_SIZE,
        }
    }
}

mod default {
    use std::time::Duration;

    pub(crate) const REFRESH_GRACE_PERIOD: Duration = Duration::from_secs(10);
    pub(crate) const MAX_AUTO_REFRESH_INTERVAL: Duration = Duration::from_secs(30);
    pub(crate) const MIN_AUTO_REFRESH_INTERVAL: Duration = Duration::from_secs(5);
    pub(crate) const EPOCH_CHANGE_DISTANCE_THRS: Duration = Duration::from_secs(300);
    pub const REFRESHER_CHANNEL_SIZE: usize = 100;
}

/// The kind of request that the client can request.
#[derive(Debug, Clone)]
pub enum RequestKind {
    /// Request the current committees and the price computation.
    Get,
    /// Get the current committees and the price computation, and refresh the cache.
    Refresh,
}

/// The request that the client can make to the refresher.
#[derive(Debug)]
pub struct CommitteesRequest {
    /// The kind of request.
    kind: RequestKind,
    /// The reply channel.
    tx: CommitteesRequestChannel,
}

impl CommitteesRequest {
    /// Returns the reply oneshot channel.
    pub fn into_reply_channel(self) -> CommitteesRequestChannel {
        self.tx
    }

    /// Returns true if the request is of kind `Refresh`.
    pub fn is_refresh(&self) -> bool {
        matches!(self.kind, RequestKind::Refresh)
    }
}

/// An actor that caches the active committees and the price computation data, and refreshes them
/// periodically or on demand.
#[derive(Debug)]
pub struct CommitteesRefresher<T> {
    last_refresh: Instant,
    last_committees: Arc<ActiveCommittees>,
    last_price_computation: PriceComputation,
    // The `epoch_state` is used to compute when the next epoch will likely start.
    epoch_state: EpochState,
    // The `epoch_duration` is used to compute when the next epoch will likely start.
    // NOTE: `epoch_duration` is set at creation, and never refreshed, since it cannot be changed.
    epoch_duration: Duration,
    notify: Arc<Notify>,
    sui_client: T,
    req_rx: mpsc::Receiver<CommitteesRequest>,
    config: CommitteesRefreshConfig,
}

impl<T: ReadClient> CommitteesRefresher<T> {
    /// Creates a new refresher cache.
    pub async fn new(
        config: CommitteesRefreshConfig,
        sui_client: T,
        req_rx: mpsc::Receiver<CommitteesRequest>,
        notify: Arc<Notify>,
    ) -> Result<Self> {
        let (committees, last_price_computation, epoch_state) =
            Self::get_latest(&sui_client).await?;
        // Get the epoch duration, this time only only.
        let epoch_duration = sui_client.fixed_system_parameters().await?.epoch_duration;

        Ok(Self {
            config,
            last_refresh: Instant::now(),
            last_committees: Arc::new(committees),
            epoch_state,
            epoch_duration,
            last_price_computation,
            notify,
            sui_client,
            req_rx,
        })
    }

    /// Runs the refresher cache.
    pub async fn run(&mut self) {
        loop {
            let timer_interval = self.next_refresh_interval();
            tokio::select! {
                _ = tokio::time::sleep(timer_interval) => {
                    // Refresh automatically.
                    // This is a safeguard against the case where only very long operations occur
                    // during epoch change. When close to the next epoch change, the refresh timer
                    // goes down to `MIN_AUTO_REFRESH_INTERVAL`, ensuring that when epoch change
                    // occurs it is detected and the operations are notified.
                    //
                    // This is a force refresh (ignores cache staleness). However, the
                    // `last_refresh` instant is not updated, so that if a running store
                    // operation detects epoch change it can still force the refresh.
                    tracing::debug!(
                        ?timer_interval,
                        "auto-refreshing the active committee"
                    );
                    let _ = self.refresh().await.inspect_err(|error| {
                        tracing::error!(
                            %error,
                            "failed to refresh the active committee; \
                            retrying again at the next interval",
                        )
                    });
                }
                request = self.req_rx.recv() => {
                    if let Some(request) = request {
                        tracing::trace!(
                            "received a request"
                        );
                        if request.is_refresh() {
                            let _ = self.refresh_if_stale().await.inspect_err(|error| {
                                tracing::error!(
                                    %error,
                                    "failed to refresh the active committee; \
                                    retrying again at the next interval",
                                )
                            });
                        }
                        let _ = request
                            .into_reply_channel()
                            .send((
                                self.last_committees.clone(),
                                self.last_price_computation.clone(),
                            ))
                            .inspect_err(|_| {
                                // This may happen because the client was notified of a committee
                                // change, and therefore the receiver end of the channel was
                                // dropped.
                                tracing::info!("failed to send the committee and price")
                            });
                    } else {
                        tracing::info!("the channel is closed, stopping the refresher");
                        break;
                    }
                }
            }
        }
    }

    /// Refreshes the data in the cache if the last refresh is older than the refresh interval.
    pub async fn refresh_if_stale(&mut self) -> Result<()> {
        if self.last_refresh.elapsed() > self.config.refresh_grace_period {
            tracing::debug!(
                elapsed = ?self.last_refresh.elapsed(),
                "the active committee is stale, refreshing"
            );
            self.refresh().await?;
            self.last_refresh = Instant::now();
        } else {
            tracing::trace!(
                elapsed = ?self.last_refresh.elapsed(),
                "the active committee was force-refreshed recently, skipping refresh"
            );
        }
        Ok(())
    }

    /// Refreshes the data in the cache and _notifies_ the clients if the committee has changed.
    ///
    /// This function does _not_ update the last refresh time.
    async fn refresh(&mut self) -> Result<()> {
        tracing::debug!("getting the latest active committee and price computation from chain");
        let (committees, price_computation, epoch_state) =
            Self::get_latest(&self.sui_client).await?;

        // First update, then notify if needed.
        let are_different =
            are_current_previous_different(&committees, self.last_committees.as_ref());
        self.last_committees = Arc::new(committees);
        self.last_price_computation = price_computation;
        self.epoch_state = epoch_state;

        // If the committee has changed, send a notification to the clients.
        if are_different {
            tracing::debug!("the active committees have changed, notifying the clients");
            self.notify.notify_waiters();
        } else {
            tracing::trace!("the active committee has not changed");
        }

        Ok(())
    }

    /// Gets the latest active committees, price computation, and epoch state from the Sui client.
    async fn get_latest(
        sui_client: &T,
    ) -> Result<(ActiveCommittees, PriceComputation, EpochState)> {
        let committees_and_state = sui_client.get_committees_and_state().await?;
        let epoch_state = committees_and_state.epoch_state.clone();
        let committees = ActiveCommittees::from_committees_and_state(committees_and_state);

        let (storage_price, write_price) =
            sui_client.storage_and_write_price_per_unit_size().await?;
        let price_computation = PriceComputation::new(storage_price, write_price);
        Ok((committees, price_computation, epoch_state))
    }

    /// Computes the start of the next epoch, based on current information.
    fn next_epoch_start(&self) -> DateTime<Utc> {
        let estimated_start_of_current_epoch = match self.epoch_state {
            EpochState::EpochChangeDone(epoch_start)
            | EpochState::NextParamsSelected(epoch_start) => epoch_start,
            EpochState::EpochChangeSync(_) => Utc::now(),
        };

        estimated_start_of_current_epoch + self.epoch_duration
    }

    /// Computes the time from now to the start of the next epoch.
    ///
    /// Returns `Duration::default()` (duration of `0`) if the subtraction overflows, i.e., if the
    /// estimated start of the next epoch is in the past.
    fn time_to_next_epoch(&self) -> Duration {
        self.next_epoch_start()
            .signed_duration_since(Utc::now())
            .to_std()
            .unwrap_or_default()
    }

    /// Returns the duration until the next refresh timer.
    ///
    /// The duration to the next timer is a function of the time to the next epoch. The refresh
    /// timer is:
    /// - `MAX_AUTO_REFRESH_INTERVAL` if the expected epoch change is more than
    ///   `EPOCH_CHANGE_DISTANCE_THRS` in the future.
    /// - `MIN_AUTO_REFRESH_INTERVAL` otherwise.
    fn next_refresh_interval(&self) -> Duration {
        if self.time_to_next_epoch() > self.config.epoch_change_distance_threshold {
            self.config.max_auto_refresh_interval
        } else {
            self.config.min_auto_refresh_interval
        }
    }
}

/// An error that occurs when communicating with the refresher.
#[derive(Debug, thiserror::Error)]
pub enum RefresherCommunicationError {
    #[error("error communicating with the refresher: {0}")]
    Send(#[from] mpsc::error::SendError<CommitteesRequest>),
    #[error("error receiving from the refresher: {0}")]
    Receive(#[from] oneshot::error::RecvError),
}

/// A handle to communicate with the [`CommitteesRefresher`].
#[derive(Debug, Clone)]
pub struct CommitteesRefresherHandle {
    notify: Arc<Notify>,
    req_tx: mpsc::Sender<CommitteesRequest>,
}

impl CommitteesRefresherHandle {
    /// Creates a new handle to communicate with the refresher.
    pub fn new(notify: Arc<Notify>, req_tx: mpsc::Sender<CommitteesRequest>) -> Self {
        Self { notify, req_tx }
    }

    /// Sends a request to the refresher to refresh and get the active committees and the price
    /// computation.
    pub async fn send_committees_and_price_request(
        &self,
        kind: RequestKind,
    ) -> Result<(Arc<ActiveCommittees>, PriceComputation), RefresherCommunicationError> {
        let (tx, rx) = oneshot::channel();
        self.req_tx.send(CommitteesRequest { kind, tx }).await?;
        let (committees, price_computation) = rx.await?;
        Ok((committees, price_computation))
    }

    /// Awaits for a notification from the refresher that the active committee has changed.
    pub async fn change_notified(&self) {
        self.notify.notified().await
    }
}

/// Checks if two committes are different enough to require a notification to the clients.
pub(crate) fn are_current_previous_different(
    first: &ActiveCommittees,
    second: &ActiveCommittees,
) -> bool {
    // Compare the current committees.
    if let Err(error) = first
        .current_committee()
        .compare_functional_equivalence(second.current_committee())
    {
        tracing::debug!(differences = %error, "current committees are different");
        return true;
    }

    // Compare the previous committees, if present.
    let previous_comparison = match (first.previous_committee(), second.previous_committee()) {
        (Some(first_previous), Some(second_previous)) => {
            first_previous.compare_functional_equivalence(second_previous)
        }
        (None, None) => Ok(()),
        _ => Err(anyhow::anyhow!(
            "one of the two sets has a previous committee, the other does not"
        )),
    };
    if let Err(error) = previous_comparison {
        tracing::debug!(differences = %error, "previous committees are different");
        return true;
    }

    false
}
