class Subscription < ActiveRecord::Base
  Balanced.configure(ENV['BALANCED_API_KEY'])

  attr_accessor :first_deposit, :second_deposit
  validates_presence_of :account_uri

  belongs_to :user
  has_many :payments

  before_create :create_verification

  after_update :create_payment, if: :confirming_account?

  before_update :confirm_verification, if: :confirming_account?

  def create_verification
    bank_account = Balanced::BankAccount.fetch(account_uri)
    verification = bank_account.verify
    self.verification_uri = verification.href
  end

  def confirm_verification
    begin
      verification = Balanced::BankAccountVerification.fetch(verification_uri)
      verification_response = verification.confirm(first_deposit, second_deposit)
      self.verified = true if verification_response.verification_status == "succeeded"
    rescue
      false
    end
  end

private

  def create_payment
    self.payments.create(amount: 65000)
  end

  def confirming_account?
    first_deposit && second_deposit
  end
end
