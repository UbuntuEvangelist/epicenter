class EnrollmentAgreementController < SignaturesController

  def new
    controller_for_next_page = 'payment_methods'
    super(RefundPolicy, EnrollmentAgreement, controller_for_next_page)
  end
end
