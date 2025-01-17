describe PaymentSerializer, :stripe_mock, :stub_mailgun, :vcr do

  it 'includes the expected attributes for a payment' do
    student = FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_credit_card)
    payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
    serialized_payment = PaymentSerializer.new(payment).as_json
    expect(serialized_payment[:amount]).to eq 60000
    expect(serialized_payment[:refund_amount]).to eq nil
    expect(serialized_payment[:email]).to eq student.email
    expect(serialized_payment[:office]).to eq student.cohort.office.short_name
    expect(serialized_payment[:start_date]).to eq student.courses.first.start_date.to_s
    expect(serialized_payment[:end_date]).to eq student.courses.last.end_date.to_s
    expect(serialized_payment[:cohort]).to eq student.cohort.description
  end

  it 'includes the expected attributes for a refund' do
    student = FactoryBot.create(:student, :with_ft_cohort, :with_plan, :with_credit_card)
    payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00, refund_amount: 100_00, refund_date: student.course.start_date)
    serialized_payment = PaymentSerializer.new(payment).as_json
    expect(serialized_payment[:amount]).to eq 60000
    expect(serialized_payment[:refund_amount]).to eq 10000
    expect(serialized_payment[:email]).to eq student.email
    expect(serialized_payment[:office]).to eq student.cohort.office.short_name
    expect(serialized_payment[:start_date]).to eq student.courses.first.start_date.to_s
    expect(serialized_payment[:end_date]).to eq student.courses.last.end_date.to_s
    expect(serialized_payment[:cohort]).to eq student.cohort.description
  end

  it 'does not set office to SEA for Washingtonians if in PDX cohort' do
    allow_any_instance_of(Student).to receive(:washingtonian?).and_return true
    student = FactoryBot.create(:portland_student, :with_ft_cohort, :with_plan, :with_credit_card)
    payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00, refund_amount: 100_00, refund_date: student.course.start_date)
    serialized_payment = PaymentSerializer.new(payment).as_json
    expect(serialized_payment[:office]).to eq 'PDX'
  end

  it 'does not set office to SEA for non-Washingtonians in WEB cohort' do
    allow_any_instance_of(Student).to receive(:washingtonian?).and_return false
    student = FactoryBot.create(:online_student, :with_ft_online_cohort, :with_plan, :with_credit_card)
    payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00, refund_amount: 100_00, refund_date: student.course.start_date)
    serialized_payment = PaymentSerializer.new(payment).as_json
    expect(serialized_payment[:office]).to eq 'WEB'
  end

  it 'sets office to SEA for Washingtonians in WEB cohort' do
    allow_any_instance_of(Student).to receive(:washingtonian?).and_return true
    student = FactoryBot.create(:online_student, :with_ft_online_cohort, :with_plan, :with_credit_card)
    payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00, refund_amount: 100_00, refund_date: student.course.start_date)
    serialized_payment = PaymentSerializer.new(payment).as_json
    expect(serialized_payment[:office]).to eq 'SEA'
  end
end
