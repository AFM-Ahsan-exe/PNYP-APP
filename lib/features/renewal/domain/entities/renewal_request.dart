import 'package:cloud_firestore/cloud_firestore.dart';

class RenewalRequest {
  final String uid;
  final String membershipType;
  final String paymentProofUrl;
  final DateTime submittedAt;
  final String status;

  const RenewalRequest({
    required this.uid,
    required this.membershipType,
    required this.paymentProofUrl,
    required this.submittedAt,
    this.status = 'pending',
  });

  factory RenewalRequest.fromJson(Map<String, dynamic> json) {
    return RenewalRequest(
      uid: json['userId'] as String? ?? json['uid'] as String? ?? '',
      membershipType: json['membershipType'] as String? ?? 'youth_mpa',
      paymentProofUrl:
          json['proofUrl'] as String? ??
          json['paymentProofUrl'] as String? ??
          '',
      submittedAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': uid,
      'membershipType': membershipType,
      'paymentProofUrl': paymentProofUrl,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'status': status,
    };
  }
}
