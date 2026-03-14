class ProgramBeneficiarySummary {
  final String programId;
  final String programName;
  final int totalBeneficiaries;
  final String organizationId;
  final String organizationName;
  final String organizationLogoUrl;

  const ProgramBeneficiarySummary({
    required this.programId,
    required this.programName,
    required this.totalBeneficiaries,
    required this.organizationId,
    required this.organizationName,
    required this.organizationLogoUrl,
  });
}
