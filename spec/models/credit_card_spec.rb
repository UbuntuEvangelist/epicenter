describe CreditCard do
  it { should belong_to :student }
  it { should have_many :payments }
  it { should validate_presence_of :student_id }

  describe "#starting_status" do
    it "returns 'succeeded'", :stripe_mock do
      credit_card = FactoryBot.create :credit_card
      expect(credit_card.starting_status).to eq 'succeeded'
    end
  end

  describe "#calculate_fee" do
    it "returns the credit card fees for the amount given", :stripe_mock do
      credit_card = FactoryBot.create :credit_card
      expect(credit_card.calculate_fee(600_00)).to eq 18_21
    end
  end

  describe "#verified?" do
    it "returns true", :stripe_mock do
      credit_card = FactoryBot.create :credit_card
      expect(credit_card.verified?).to eq true
    end
  end

  describe "#ensure_primary_method_exists" do
    it "makes a credit card the primary payment method after create as verified is true", :stripe_mock do
      credit_card = FactoryBot.create :credit_card
      expect(credit_card.student.primary_payment_method).to eq credit_card
    end
  end
end
