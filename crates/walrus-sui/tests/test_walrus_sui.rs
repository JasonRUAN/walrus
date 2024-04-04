// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

use fastcrypto::{
    bls12381::min_pk::{BLS12381AggregateSignature, BLS12381PrivateKey},
    traits::{Signer, ToFromBytes},
};
use test_cluster::TestClusterBuilder;
use tokio_stream::StreamExt;
use walrus_core::{
    messages::{Confirmation, ConfirmationCertificate},
    BlobId,
    EncodingType,
    ShardIndex,
};
use walrus_e2e_tests::publish_package;
use walrus_sui::{
    client::{ReadClient, SuiContractClient},
    types::EpochStatus,
};

fn get_blob_cert(blob_id: BlobId, epoch: u64) -> ConfirmationCertificate {
    // Use the same private key that is registered in the committee in
    // `contracts/blob_store/e2etest.move`
    let mut sk = [0; 32];
    sk[31] = 117;
    let sk = BLS12381PrivateKey::from_bytes(&sk).unwrap();
    let confirmation = bcs::to_bytes(&Confirmation::new(epoch, blob_id)).unwrap();
    let signature = BLS12381AggregateSignature::from(sk.sign(&confirmation));
    ConfirmationCertificate {
        confirmation,
        signature,
        signers: vec![0],
    }
}

#[tokio::test]
#[ignore = "ignore integration tests by default"]
async fn test_register_blob() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();
    let test_cluster = TestClusterBuilder::new().build().await;
    let mut wallet = test_cluster.wallet;
    let (package_id, system_object) = publish_package(&mut wallet, "blob_store").await?;
    let walrus_client =
        SuiContractClient::new(wallet, package_id, system_object, 10000000000).await?;

    // Get event streams for the events
    let polling_duration = std::time::Duration::from_millis(50);
    let mut registered_events = walrus_client
        .read_client
        .blob_registered_events(polling_duration, None)
        .await?;
    let mut certified_events = walrus_client
        .read_client
        .blob_certified_events(polling_duration, None)
        .await?;

    let size = 10000;
    let storage_resource = walrus_client.reserve_space(size, 3).await?;
    assert_eq!(storage_resource.start_epoch, 0);
    assert_eq!(storage_resource.end_epoch, 3);
    assert_eq!(storage_resource.storage_size, size);
    #[rustfmt::skip]
    let blob_id = BlobId([
        1, 2, 3, 4, 5, 6, 7, 8,
        1, 2, 3, 4, 5, 6, 7, 8,
        1, 2, 3, 4, 5, 6, 7, 8,
        1, 2, 3, 4, 5, 6, 7, 8,
    ]);
    let blob_obj = walrus_client
        .register_blob(&storage_resource, blob_id, size, EncodingType::RedStuff)
        .await?;
    assert_eq!(blob_obj.blob_id, blob_id);
    assert_eq!(blob_obj.encoded_size, size);
    assert_eq!(blob_obj.certified, None);
    assert_eq!(blob_obj.storage, storage_resource);
    assert_eq!(blob_obj.stored_epoch, 0);

    // Make sure that we got the expected event
    let blob_registered = registered_events.next().await.unwrap();
    assert_eq!(blob_registered.blob_id, blob_id);
    assert_eq!(blob_registered.epoch, blob_obj.stored_epoch);
    assert_eq!(
        blob_registered.erasure_code_type,
        blob_obj.erasure_code_type
    );
    assert_eq!(blob_registered.end_epoch, storage_resource.end_epoch);
    assert_eq!(blob_registered.size, blob_obj.encoded_size);

    let blob_obj = walrus_client
        .certify_blob(&blob_obj, &get_blob_cert(blob_id, 0))
        .await?;
    assert_eq!(blob_obj.certified, Some(0));

    // Make sure that we got the expected event
    let blob_certified = certified_events.next().await.unwrap();
    assert_eq!(blob_certified.blob_id, blob_id);
    assert_eq!(Some(blob_registered.epoch), blob_obj.certified);
    assert_eq!(blob_certified.end_epoch, storage_resource.end_epoch);

    // Drop event streams
    let _ = registered_events;
    let _ = certified_events;
    // Get new event streams with cursors
    let mut registered_events = walrus_client
        .read_client
        .blob_registered_events(polling_duration, Some(blob_registered.event_id))
        .await?;
    let mut certified_events = walrus_client
        .read_client
        .blob_certified_events(polling_duration, Some(blob_certified.event_id))
        .await?;

    // Now register and certify a blob with a different blob id again to check that
    // we receive the event
    let storage_resource = walrus_client.reserve_space(size, 3).await?;
    #[rustfmt::skip]
    let blob_id = BlobId([
        1, 2, 3, 4, 5, 6, 7, 0,
        1, 2, 3, 4, 5, 6, 7, 0,
        1, 2, 3, 4, 5, 6, 7, 0,
        1, 2, 3, 4, 5, 6, 7, 0,
    ]);
    let blob_obj = walrus_client
        .register_blob(&storage_resource, blob_id, size, EncodingType::RedStuff)
        .await?;

    // Make sure that we got the expected event
    let blob_registered = registered_events.next().await.unwrap();
    assert_eq!(blob_registered.blob_id, blob_id);

    let _blob_obj = walrus_client
        .certify_blob(&blob_obj, &get_blob_cert(blob_id, 0))
        .await?;

    // Make sure that we got the expected event
    let blob_certified = certified_events.next().await.unwrap();
    assert_eq!(blob_certified.blob_id, blob_id);

    Ok(())
}

#[tokio::test]
#[ignore = "ignore integration tests by default"]
async fn test_get_system() -> anyhow::Result<()> {
    let test_cluster = TestClusterBuilder::new().build().await;
    let mut wallet = test_cluster.wallet;
    let (package_id, system_object) = publish_package(&mut wallet, "blob_store").await?;
    let walrus_client =
        SuiContractClient::new(wallet, package_id, system_object, 10000000000).await?;
    let system = walrus_client.read_client.get_system_object().await?;
    assert_eq!(system.epoch_status, EpochStatus::Done);
    assert_eq!(system.price_per_unit_size, 10);
    assert_eq!(system.total_capacity_size, 1000000000);
    assert_eq!(system.used_capacity_size, 0);
    let committee = walrus_client.read_client.current_committee().await?;
    assert_eq!(system.current_committee, committee);
    assert_eq!(committee.epoch, 0);
    assert_eq!(committee.total_weight, 10);
    assert_eq!(committee.members.len(), 1);
    let storage_node = &committee.members[0];
    assert_eq!(storage_node.name, "Test0");
    assert_eq!(storage_node.network_address.to_string(), "127.0.0.1:8080");
    assert_eq!(
        storage_node.shard_ids,
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
            .into_iter()
            .map(ShardIndex)
            .collect::<Vec<_>>()
    );
    assert_eq!(
        storage_node.public_key.as_bytes(),
        [
            149, 234, 204, 58, 220, 9, 200, 39, 89, 63, 88, 30, 142, 45, 224, 104, 191, 76, 245,
            208, 192, 235, 41, 229, 55, 47, 13, 35, 54, 71, 136, 238, 15, 155, 235, 17, 44, 138,
            126, 156, 47, 12, 114, 4, 51, 112, 92, 240
        ]
    );
    Ok(())
}
