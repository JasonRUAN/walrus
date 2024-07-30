// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

// editorconfig-checker-disable-file
// Data here autogenerated by python file

// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module walrus::bls_tests;

use sui::bls12381::bls12381_min_pk_verify;

use walrus::bls_aggregate::{Self, BlsCommittee, new_bls_committee, verify_certificate};
use walrus::storage_node;

#[test]
public fun test_basic_compatibility(){

    // Check the basic python compatibility

    let pub_key_bytes = vector[142, 78, 70, 3, 179, 142, 145, 75, 170, 36, 5, 232, 153, 164, 205, 57, 24, 216, 208, 34, 87, 213, 225, 76, 5, 157, 212, 88, 161, 34, 75, 145, 206, 144, 85, 11, 197, 110, 75, 175, 215, 194, 78, 51, 192, 196, 59, 204];
    let message = vector[104, 101, 108, 108, 111];
    let signature = vector[167, 32, 44, 82, 208, 22, 233, 67, 235, 217, 254, 68, 183, 43, 226, 203, 148, 213, 13, 105, 152, 28, 1, 169, 159, 62, 217, 47, 175, 237, 162, 94, 2, 38, 239, 56, 181, 123, 19, 123, 93, 253, 16, 64, 9, 109, 42, 3, 14, 11, 80, 109, 92, 8, 61, 88, 246, 66, 65, 15, 235, 232, 216, 240, 96, 192, 77, 134, 179, 40, 232, 125, 35, 136, 196, 16, 24, 52, 145, 128, 9, 42, 206, 191, 49, 91, 139, 252, 25, 5, 167, 199, 132, 203, 25, 154];

    assert!(bls12381_min_pk_verify(
        &signature,
        &pub_key_bytes,
        &message), 0);

}

#[test]
public fun test_check_aggregate(): BlsCommittee {
    let pk0 = vector[166, 14, 117, 25, 14, 98, 182, 165, 65, 66, 209, 71, 40, 154, 115, 92, 76, 225, 26, 157, 153, 117, 67, 218, 83, 154, 61, 181, 125, 239, 94, 216, 59, 164, 11, 116, 229, 80, 101, 240, 43, 53, 170, 29, 80, 76, 64, 75];
    let pk1 = vector[174, 18, 3, 148, 89, 198, 4, 145, 103, 43, 106, 98, 130, 53, 93, 135, 101, 186, 98, 114, 56, 127, 185, 26, 62, 150, 4, 250, 42, 129, 69, 12, 241, 107, 135, 11, 180, 70, 252, 58, 62, 10, 24, 127, 255, 111, 137, 69];
    let pk2 = vector[148, 123, 50, 124, 138, 21, 179, 150, 52, 164, 38, 175, 112, 192, 98, 181, 6, 50, 167, 68, 237, 221, 65, 181, 164, 104, 100, 20, 239, 76, 217, 116, 107, 177, 29, 10, 83, 198, 194, 255, 33, 187, 207, 51, 30, 7, 172, 146];
    let pk3 = vector[133, 252, 74, 229, 67, 202, 22, 36, 116, 88, 110, 118, 215, 44, 71, 208, 21, 28, 60, 183, 183, 126, 130, 200, 126, 85, 74, 191, 114, 84, 142, 46, 116, 107, 198, 117, 128, 91, 104, 139, 80, 22, 38, 158, 24, 255, 66, 80];
    let pk4 = vector[140, 170, 13, 232, 98, 121, 62, 86, 124, 96, 80, 170, 130, 45, 178, 214, 203, 43, 82, 11, 198, 43, 109, 188, 186, 126, 119, 48, 103, 237, 9, 199, 186, 2, 130, 215, 194, 14, 1, 80, 12, 108, 47, 167, 100, 8, 173, 237];
    let pk5 = vector[170, 39, 63, 208, 83, 35, 225, 56, 30, 16, 233, 62, 104, 60, 52, 100, 115, 40, 18, 112, 32, 179, 80, 127, 200, 205, 220, 51, 112, 56, 227, 63, 189, 122, 153, 239, 13, 44, 123, 106, 39, 141, 127, 129, 22, 22, 37, 96];
    let pk6 = vector[143, 206, 207, 249, 174, 4, 144, 247, 35, 18, 56, 34, 198, 111, 54, 153, 109, 35, 116, 144, 214, 118, 158, 230, 143, 159, 122, 125, 161, 198, 186, 200, 181, 195, 208, 196, 52, 142, 140, 232, 252, 61, 81, 89, 248, 51, 52, 132];
    let pk7 = vector[143, 79, 254, 129, 165, 12, 241, 23, 6, 156, 154, 102, 173, 159, 39, 118, 238, 234, 233, 79, 224, 43, 162, 160, 249, 89, 108, 183, 152, 249, 229, 189, 244, 113, 159, 206, 170, 97, 116, 111, 254, 36, 8, 242, 91, 86, 217, 110];
    let pk8 = vector[135, 133, 64, 95, 39, 94, 226, 253, 147, 78, 131, 131, 90, 121, 186, 101, 31, 128, 176, 244, 50, 223, 27, 128, 99, 80, 220, 148, 156, 22, 156, 96, 230, 7, 103, 228, 31, 174, 216, 234, 172, 94, 208, 233, 226, 16, 120, 124];
    let pk9 = vector[128, 173, 226, 9, 19, 120, 41, 58, 99, 213, 83, 40, 206, 242, 55, 54, 244, 219, 220, 73, 189, 60, 7, 135, 184, 193, 140, 214, 168, 221, 194, 212, 42, 39, 146, 66, 232, 123, 34, 209, 144, 159, 63, 29, 85, 229, 218, 102];
    let message = vector[104, 101, 108, 108, 111];

    // This is the aggregate sig for keys 0, 1, 2, 3, 4, 5, 6
    let agg_sig = vector[134, 145, 54, 247, 223, 68, 1, 65, 112, 10, 160, 125, 172, 100, 93, 62, 192, 216, 7, 129, 27, 180, 99, 101, 45, 248, 123, 114, 102, 97, 180, 101, 8, 246, 118, 94, 149, 82, 158, 181, 134, 28, 177, 85, 241, 53, 152, 176, 22, 227, 147, 88, 180, 160, 138, 174, 97, 9, 70, 172, 29, 128, 192, 254, 252, 43, 131, 182, 120, 126, 203, 191, 202, 186, 23, 179, 170, 184, 146, 236, 83, 21, 7, 2, 177, 103, 103, 138, 13, 41, 47, 180, 1, 156, 29, 162];

    // Make a new committee
    let committee = new_bls_committee(
        vector[
            storage_node::new_for_testing(pk0, 1), storage_node::new_for_testing(pk1, 1), storage_node::new_for_testing(pk2, 1), storage_node::new_for_testing(pk3, 1), storage_node::new_for_testing(pk4, 1), storage_node::new_for_testing(pk5, 1), storage_node::new_for_testing(pk6, 1), storage_node::new_for_testing(pk7, 1), storage_node::new_for_testing(pk8, 1), storage_node::new_for_testing(pk9, 1)
        ]
    );

    // Verify the aggregate signature
    verify_certificate(
        &committee,
        &agg_sig,
        &vector[0, 1, 2, 3, 4, 5, 6],
        &message
    );

    committee

}

#[test, expected_failure(abort_code = bls_aggregate::ESigVerification) ]
public fun test_add_members_error(): BlsCommittee {
    let pk0 = vector[166, 14, 117, 25, 14, 98, 182, 165, 65, 66, 209, 71, 40, 154, 115, 92, 76, 225, 26, 157, 153, 117, 67, 218, 83, 154, 61, 181, 125, 239, 94, 216, 59, 164, 11, 116, 229, 80, 101, 240, 43, 53, 170, 29, 80, 76, 64, 75];
    let pk1 = vector[174, 18, 3, 148, 89, 198, 4, 145, 103, 43, 106, 98, 130, 53, 93, 135, 101, 186, 98, 114, 56, 127, 185, 26, 62, 150, 4, 250, 42, 129, 69, 12, 241, 107, 135, 11, 180, 70, 252, 58, 62, 10, 24, 127, 255, 111, 137, 69];
    let pk2 = vector[148, 123, 50, 124, 138, 21, 179, 150, 52, 164, 38, 175, 112, 192, 98, 181, 6, 50, 167, 68, 237, 221, 65, 181, 164, 104, 100, 20, 239, 76, 217, 116, 107, 177, 29, 10, 83, 198, 194, 255, 33, 187, 207, 51, 30, 7, 172, 146];
    let pk3 = vector[133, 252, 74, 229, 67, 202, 22, 36, 116, 88, 110, 118, 215, 44, 71, 208, 21, 28, 60, 183, 183, 126, 130, 200, 126, 85, 74, 191, 114, 84, 142, 46, 116, 107, 198, 117, 128, 91, 104, 139, 80, 22, 38, 158, 24, 255, 66, 80];
    let pk4 = vector[140, 170, 13, 232, 98, 121, 62, 86, 124, 96, 80, 170, 130, 45, 178, 214, 203, 43, 82, 11, 198, 43, 109, 188, 186, 126, 119, 48, 103, 237, 9, 199, 186, 2, 130, 215, 194, 14, 1, 80, 12, 108, 47, 167, 100, 8, 173, 237];
    let pk5 = vector[170, 39, 63, 208, 83, 35, 225, 56, 30, 16, 233, 62, 104, 60, 52, 100, 115, 40, 18, 112, 32, 179, 80, 127, 200, 205, 220, 51, 112, 56, 227, 63, 189, 122, 153, 239, 13, 44, 123, 106, 39, 141, 127, 129, 22, 22, 37, 96];
    let pk6 = vector[143, 206, 207, 249, 174, 4, 144, 247, 35, 18, 56, 34, 198, 111, 54, 153, 109, 35, 116, 144, 214, 118, 158, 230, 143, 159, 122, 125, 161, 198, 186, 200, 181, 195, 208, 196, 52, 142, 140, 232, 252, 61, 81, 89, 248, 51, 52, 132];
    let pk7 = vector[143, 79, 254, 129, 165, 12, 241, 23, 6, 156, 154, 102, 173, 159, 39, 118, 238, 234, 233, 79, 224, 43, 162, 160, 249, 89, 108, 183, 152, 249, 229, 189, 244, 113, 159, 206, 170, 97, 116, 111, 254, 36, 8, 242, 91, 86, 217, 110];
    let pk8 = vector[135, 133, 64, 95, 39, 94, 226, 253, 147, 78, 131, 131, 90, 121, 186, 101, 31, 128, 176, 244, 50, 223, 27, 128, 99, 80, 220, 148, 156, 22, 156, 96, 230, 7, 103, 228, 31, 174, 216, 234, 172, 94, 208, 233, 226, 16, 120, 124];
    let pk9 = vector[128, 173, 226, 9, 19, 120, 41, 58, 99, 213, 83, 40, 206, 242, 55, 54, 244, 219, 220, 73, 189, 60, 7, 135, 184, 193, 140, 214, 168, 221, 194, 212, 42, 39, 146, 66, 232, 123, 34, 209, 144, 159, 63, 29, 85, 229, 218, 102];
    let message = vector[104, 101, 108, 108, 111];
    let agg_sig = vector[134, 145, 54, 247, 223, 68, 1, 65, 112, 10, 160, 125, 172, 100, 93, 62, 192, 216, 7, 129, 27, 180, 99, 101, 45, 248, 123, 114, 102, 97, 180, 101, 8, 246, 118, 94, 149, 82, 158, 181, 134, 28, 177, 85, 241, 53, 152, 176, 22, 227, 147, 88, 180, 160, 138, 174, 97, 9, 70, 172, 29, 128, 192, 254, 252, 43, 131, 182, 120, 126, 203, 191, 202, 186, 23, 179, 170, 184, 146, 236, 83, 21, 7, 2, 177, 103, 103, 138, 13, 41, 47, 180, 1, 156, 29, 162];

    // Make a new committee
    let committee = new_bls_committee(
        vector[
            storage_node::new_for_testing(pk0, 1), storage_node::new_for_testing(pk1, 1), storage_node::new_for_testing(pk2, 1), storage_node::new_for_testing(pk3, 1), storage_node::new_for_testing(pk4, 1), storage_node::new_for_testing(pk5, 1), storage_node::new_for_testing(pk6, 1), storage_node::new_for_testing(pk7, 1), storage_node::new_for_testing(pk8, 1), storage_node::new_for_testing(pk9, 1)
        ]
    );

    // Verify the aggregate signature
    verify_certificate(
        &committee,
        &agg_sig,
        &vector[0, 1, 2, 3, 4, 5, 6, 7],
        &message
    );

    committee

}

#[test, expected_failure(abort_code = bls_aggregate::ESigVerification) ]
public fun test_incorrect_signature_error(): BlsCommittee {
    let pk0 = vector[166, 14, 117, 25, 14, 98, 182, 165, 65, 66, 209, 71, 40, 154, 115, 92, 76, 225, 26, 157, 153, 117, 67, 218, 83, 154, 61, 181, 125, 239, 94, 216, 59, 164, 11, 116, 229, 80, 101, 240, 43, 53, 170, 29, 80, 76, 64, 75];
    let pk1 = vector[174, 18, 3, 148, 89, 198, 4, 145, 103, 43, 106, 98, 130, 53, 93, 135, 101, 186, 98, 114, 56, 127, 185, 26, 62, 150, 4, 250, 42, 129, 69, 12, 241, 107, 135, 11, 180, 70, 252, 58, 62, 10, 24, 127, 255, 111, 137, 69];
    let pk2 = vector[148, 123, 50, 124, 138, 21, 179, 150, 52, 164, 38, 175, 112, 192, 98, 181, 6, 50, 167, 68, 237, 221, 65, 181, 164, 104, 100, 20, 239, 76, 217, 116, 107, 177, 29, 10, 83, 198, 194, 255, 33, 187, 207, 51, 30, 7, 172, 146];
    let pk3 = vector[133, 252, 74, 229, 67, 202, 22, 36, 116, 88, 110, 118, 215, 44, 71, 208, 21, 28, 60, 183, 183, 126, 130, 200, 126, 85, 74, 191, 114, 84, 142, 46, 116, 107, 198, 117, 128, 91, 104, 139, 80, 22, 38, 158, 24, 255, 66, 80];
    let pk4 = vector[140, 170, 13, 232, 98, 121, 62, 86, 124, 96, 80, 170, 130, 45, 178, 214, 203, 43, 82, 11, 198, 43, 109, 188, 186, 126, 119, 48, 103, 237, 9, 199, 186, 2, 130, 215, 194, 14, 1, 80, 12, 108, 47, 167, 100, 8, 173, 237];
    let pk5 = vector[170, 39, 63, 208, 83, 35, 225, 56, 30, 16, 233, 62, 104, 60, 52, 100, 115, 40, 18, 112, 32, 179, 80, 127, 200, 205, 220, 51, 112, 56, 227, 63, 189, 122, 153, 239, 13, 44, 123, 106, 39, 141, 127, 129, 22, 22, 37, 96];
    let pk6 = vector[143, 206, 207, 249, 174, 4, 144, 247, 35, 18, 56, 34, 198, 111, 54, 153, 109, 35, 116, 144, 214, 118, 158, 230, 143, 159, 122, 125, 161, 198, 186, 200, 181, 195, 208, 196, 52, 142, 140, 232, 252, 61, 81, 89, 248, 51, 52, 132];
    let pk7 = vector[143, 79, 254, 129, 165, 12, 241, 23, 6, 156, 154, 102, 173, 159, 39, 118, 238, 234, 233, 79, 224, 43, 162, 160, 249, 89, 108, 183, 152, 249, 229, 189, 244, 113, 159, 206, 170, 97, 116, 111, 254, 36, 8, 242, 91, 86, 217, 110];
    let pk8 = vector[135, 133, 64, 95, 39, 94, 226, 253, 147, 78, 131, 131, 90, 121, 186, 101, 31, 128, 176, 244, 50, 223, 27, 128, 99, 80, 220, 148, 156, 22, 156, 96, 230, 7, 103, 228, 31, 174, 216, 234, 172, 94, 208, 233, 226, 16, 120, 124];
    let pk9 = vector[128, 173, 226, 9, 19, 120, 41, 58, 99, 213, 83, 40, 206, 242, 55, 54, 244, 219, 220, 73, 189, 60, 7, 135, 184, 193, 140, 214, 168, 221, 194, 212, 42, 39, 146, 66, 232, 123, 34, 209, 144, 159, 63, 29, 85, 229, 218, 102];
    let message = vector[104, 101, 108, 108, 111];
    // BAD SIGNATURE
    let agg_sig = vector[133, 145, 54, 247, 223, 68, 1, 65, 112, 10, 160, 125, 172, 100, 93, 62, 192, 216, 7, 129, 27, 180, 99, 101, 45, 248, 123, 114, 102, 97, 180, 101, 8, 246, 118, 94, 149, 82, 158, 181, 134, 28, 177, 85, 241, 53, 152, 176, 22, 227, 147, 88, 180, 160, 138, 174, 97, 9, 70, 172, 29, 128, 192, 254, 252, 43, 131, 182, 120, 126, 203, 191, 202, 186, 23, 179, 170, 184, 146, 236, 83, 21, 7, 2, 177, 103, 103, 138, 13, 41, 47, 180, 1, 156, 29, 162];

    // Make a new committee
    let committee = new_bls_committee(
        vector[
            storage_node::new_for_testing(pk0, 1), storage_node::new_for_testing(pk1, 1), storage_node::new_for_testing(pk2, 1), storage_node::new_for_testing(pk3, 1), storage_node::new_for_testing(pk4, 1), storage_node::new_for_testing(pk5, 1), storage_node::new_for_testing(pk6, 1), storage_node::new_for_testing(pk7, 1), storage_node::new_for_testing(pk8, 1), storage_node::new_for_testing(pk9, 1)
        ]
    );

    // Verify the aggregate signature
    verify_certificate(
        &committee,
        &agg_sig,
        &vector[0, 1, 2, 3, 4, 5, 6],
        &message
    );

    committee

}

#[test, expected_failure(abort_code = bls_aggregate::ETotalMemberOrder) ]
public fun test_duplicate_member_error(): BlsCommittee {
    let pk0 = vector[166, 14, 117, 25, 14, 98, 182, 165, 65, 66, 209, 71, 40, 154, 115, 92, 76, 225, 26, 157, 153, 117, 67, 218, 83, 154, 61, 181, 125, 239, 94, 216, 59, 164, 11, 116, 229, 80, 101, 240, 43, 53, 170, 29, 80, 76, 64, 75];
    let pk1 = vector[174, 18, 3, 148, 89, 198, 4, 145, 103, 43, 106, 98, 130, 53, 93, 135, 101, 186, 98, 114, 56, 127, 185, 26, 62, 150, 4, 250, 42, 129, 69, 12, 241, 107, 135, 11, 180, 70, 252, 58, 62, 10, 24, 127, 255, 111, 137, 69];
    let pk2 = vector[148, 123, 50, 124, 138, 21, 179, 150, 52, 164, 38, 175, 112, 192, 98, 181, 6, 50, 167, 68, 237, 221, 65, 181, 164, 104, 100, 20, 239, 76, 217, 116, 107, 177, 29, 10, 83, 198, 194, 255, 33, 187, 207, 51, 30, 7, 172, 146];
    let pk3 = vector[133, 252, 74, 229, 67, 202, 22, 36, 116, 88, 110, 118, 215, 44, 71, 208, 21, 28, 60, 183, 183, 126, 130, 200, 126, 85, 74, 191, 114, 84, 142, 46, 116, 107, 198, 117, 128, 91, 104, 139, 80, 22, 38, 158, 24, 255, 66, 80];
    let pk4 = vector[140, 170, 13, 232, 98, 121, 62, 86, 124, 96, 80, 170, 130, 45, 178, 214, 203, 43, 82, 11, 198, 43, 109, 188, 186, 126, 119, 48, 103, 237, 9, 199, 186, 2, 130, 215, 194, 14, 1, 80, 12, 108, 47, 167, 100, 8, 173, 237];
    let pk5 = vector[170, 39, 63, 208, 83, 35, 225, 56, 30, 16, 233, 62, 104, 60, 52, 100, 115, 40, 18, 112, 32, 179, 80, 127, 200, 205, 220, 51, 112, 56, 227, 63, 189, 122, 153, 239, 13, 44, 123, 106, 39, 141, 127, 129, 22, 22, 37, 96];
    let pk6 = vector[143, 206, 207, 249, 174, 4, 144, 247, 35, 18, 56, 34, 198, 111, 54, 153, 109, 35, 116, 144, 214, 118, 158, 230, 143, 159, 122, 125, 161, 198, 186, 200, 181, 195, 208, 196, 52, 142, 140, 232, 252, 61, 81, 89, 248, 51, 52, 132];
    let pk7 = vector[143, 79, 254, 129, 165, 12, 241, 23, 6, 156, 154, 102, 173, 159, 39, 118, 238, 234, 233, 79, 224, 43, 162, 160, 249, 89, 108, 183, 152, 249, 229, 189, 244, 113, 159, 206, 170, 97, 116, 111, 254, 36, 8, 242, 91, 86, 217, 110];
    let pk8 = vector[135, 133, 64, 95, 39, 94, 226, 253, 147, 78, 131, 131, 90, 121, 186, 101, 31, 128, 176, 244, 50, 223, 27, 128, 99, 80, 220, 148, 156, 22, 156, 96, 230, 7, 103, 228, 31, 174, 216, 234, 172, 94, 208, 233, 226, 16, 120, 124];
    let pk9 = vector[128, 173, 226, 9, 19, 120, 41, 58, 99, 213, 83, 40, 206, 242, 55, 54, 244, 219, 220, 73, 189, 60, 7, 135, 184, 193, 140, 214, 168, 221, 194, 212, 42, 39, 146, 66, 232, 123, 34, 209, 144, 159, 63, 29, 85, 229, 218, 102];
    let message = vector[104, 101, 108, 108, 111];
    // BAD SIGNATURE
    let agg_sig = vector[134, 145, 54, 247, 223, 68, 1, 65, 112, 10, 160, 125, 172, 100, 93, 62, 192, 216, 7, 129, 27, 180, 99, 101, 45, 248, 123, 114, 102, 97, 180, 101, 8, 246, 118, 94, 149, 82, 158, 181, 134, 28, 177, 85, 241, 53, 152, 176, 22, 227, 147, 88, 180, 160, 138, 174, 97, 9, 70, 172, 29, 128, 192, 254, 252, 43, 131, 182, 120, 126, 203, 191, 202, 186, 23, 179, 170, 184, 146, 236, 83, 21, 7, 2, 177, 103, 103, 138, 13, 41, 47, 180, 1, 156, 29, 162];

    // Make a new committee
    let committee = new_bls_committee(
        vector[
            storage_node::new_for_testing(pk0, 1), storage_node::new_for_testing(pk1, 1), storage_node::new_for_testing(pk2, 1), storage_node::new_for_testing(pk3, 1), storage_node::new_for_testing(pk4, 1), storage_node::new_for_testing(pk5, 1), storage_node::new_for_testing(pk6, 1), storage_node::new_for_testing(pk7, 1), storage_node::new_for_testing(pk8, 1), storage_node::new_for_testing(pk9, 1)
        ]
    );

    // Verify the aggregate signature
    verify_certificate(
        &committee,
        &agg_sig,
        &vector[0, 1, 2, 3, 3, 5, 6],
        &message
    );

    committee

}

#[test, expected_failure(abort_code = bls_aggregate::ENotEnoughStake) ]
public fun test_incorrect_stake_error(): BlsCommittee {
    let pk0 = vector[166, 14, 117, 25, 14, 98, 182, 165, 65, 66, 209, 71, 40, 154, 115, 92, 76, 225, 26, 157, 153, 117, 67, 218, 83, 154, 61, 181, 125, 239, 94, 216, 59, 164, 11, 116, 229, 80, 101, 240, 43, 53, 170, 29, 80, 76, 64, 75];
    let pk1 = vector[174, 18, 3, 148, 89, 198, 4, 145, 103, 43, 106, 98, 130, 53, 93, 135, 101, 186, 98, 114, 56, 127, 185, 26, 62, 150, 4, 250, 42, 129, 69, 12, 241, 107, 135, 11, 180, 70, 252, 58, 62, 10, 24, 127, 255, 111, 137, 69];
    let pk2 = vector[148, 123, 50, 124, 138, 21, 179, 150, 52, 164, 38, 175, 112, 192, 98, 181, 6, 50, 167, 68, 237, 221, 65, 181, 164, 104, 100, 20, 239, 76, 217, 116, 107, 177, 29, 10, 83, 198, 194, 255, 33, 187, 207, 51, 30, 7, 172, 146];
    let pk3 = vector[133, 252, 74, 229, 67, 202, 22, 36, 116, 88, 110, 118, 215, 44, 71, 208, 21, 28, 60, 183, 183, 126, 130, 200, 126, 85, 74, 191, 114, 84, 142, 46, 116, 107, 198, 117, 128, 91, 104, 139, 80, 22, 38, 158, 24, 255, 66, 80];
    let pk4 = vector[140, 170, 13, 232, 98, 121, 62, 86, 124, 96, 80, 170, 130, 45, 178, 214, 203, 43, 82, 11, 198, 43, 109, 188, 186, 126, 119, 48, 103, 237, 9, 199, 186, 2, 130, 215, 194, 14, 1, 80, 12, 108, 47, 167, 100, 8, 173, 237];
    let pk5 = vector[170, 39, 63, 208, 83, 35, 225, 56, 30, 16, 233, 62, 104, 60, 52, 100, 115, 40, 18, 112, 32, 179, 80, 127, 200, 205, 220, 51, 112, 56, 227, 63, 189, 122, 153, 239, 13, 44, 123, 106, 39, 141, 127, 129, 22, 22, 37, 96];
    let pk6 = vector[143, 206, 207, 249, 174, 4, 144, 247, 35, 18, 56, 34, 198, 111, 54, 153, 109, 35, 116, 144, 214, 118, 158, 230, 143, 159, 122, 125, 161, 198, 186, 200, 181, 195, 208, 196, 52, 142, 140, 232, 252, 61, 81, 89, 248, 51, 52, 132];
    let pk7 = vector[143, 79, 254, 129, 165, 12, 241, 23, 6, 156, 154, 102, 173, 159, 39, 118, 238, 234, 233, 79, 224, 43, 162, 160, 249, 89, 108, 183, 152, 249, 229, 189, 244, 113, 159, 206, 170, 97, 116, 111, 254, 36, 8, 242, 91, 86, 217, 110];
    let pk8 = vector[135, 133, 64, 95, 39, 94, 226, 253, 147, 78, 131, 131, 90, 121, 186, 101, 31, 128, 176, 244, 50, 223, 27, 128, 99, 80, 220, 148, 156, 22, 156, 96, 230, 7, 103, 228, 31, 174, 216, 234, 172, 94, 208, 233, 226, 16, 120, 124];
    let pk9 = vector[128, 173, 226, 9, 19, 120, 41, 58, 99, 213, 83, 40, 206, 242, 55, 54, 244, 219, 220, 73, 189, 60, 7, 135, 184, 193, 140, 214, 168, 221, 194, 212, 42, 39, 146, 66, 232, 123, 34, 209, 144, 159, 63, 29, 85, 229, 218, 102];
    let message = vector[104, 101, 108, 108, 111];
    // BAD SIGNATURE
    let agg_sig = vector[134, 145, 54, 247, 223, 68, 1, 65, 112, 10, 160, 125, 172, 100, 93, 62, 192, 216, 7, 129, 27, 180, 99, 101, 45, 248, 123, 114, 102, 97, 180, 101, 8, 246, 118, 94, 149, 82, 158, 181, 134, 28, 177, 85, 241, 53, 152, 176, 22, 227, 147, 88, 180, 160, 138, 174, 97, 9, 70, 172, 29, 128, 192, 254, 252, 43, 131, 182, 120, 126, 203, 191, 202, 186, 23, 179, 170, 184, 146, 236, 83, 21, 7, 2, 177, 103, 103, 138, 13, 41, 47, 180, 1, 156, 29, 162];

    // Make a new committee
    let committee = new_bls_committee(
        vector[
            storage_node::new_for_testing(pk0, 1), storage_node::new_for_testing(pk1, 2), storage_node::new_for_testing(pk2, 2), storage_node::new_for_testing(pk3, 2), storage_node::new_for_testing(pk4, 2), storage_node::new_for_testing(pk5, 2), storage_node::new_for_testing(pk6, 2), storage_node::new_for_testing(pk7, 2), storage_node::new_for_testing(pk8, 2), storage_node::new_for_testing(pk9, 3)
        ]
    );

    // Verify the aggregate signature
    verify_certificate(
        &committee,
        &agg_sig,
        &vector[0, 1, 2, 3, 4, 5, 6],
        &message
    );

    committee

}
