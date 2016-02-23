feature 'Viewing payment index page' do
  scenario 'as a guest' do
    student = FactoryGirl.create(:student)
    visit student_payments_path(student)
    expect(page).to have_content 'need to sign in'
  end

  context 'as a student' do
    scenario "without a primary payment method" do
      student = FactoryGirl.create(:user_with_all_documents_signed)
      login_as(student, scope: :student)
      visit student_payments_path(student)
      expect(page).to have_content "Your payment methods"
    end

    context "viewing another student's payments page", :stripe_mock do
      it "doesn't show payment history" do
        student = FactoryGirl.create(:user_with_all_documents_signed_and_credit_card)
        student_2 = FactoryGirl.create(:user_with_all_documents_signed_and_credit_card)
        login_as(student, scope: :student)
        visit student_payments_path(student_2)
        expect(page).to have_content "You are not authorized to access this page."
      end
    end

    context 'before any payments have been made', :stripe_mock do
      it "doesn't show payment history" do
        student = FactoryGirl.create(:user_with_credit_card)
        login_as(student, scope: :student)
        visit student_payments_path(student)
        expect(page).to have_content "No payments have been made yet."
      end
    end

    context 'after a payment has been made with bank account', :vcr, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryGirl.create(:user_with_verified_bank_account, email: 'test@test.com')
        payment = FactoryGirl.create(:payment_with_bank_account, amount: 600_00, student: student)
        login_as(student, scope: :student)
        visit student_payments_path(student)
        expect(page).to have_content 600.00
        expect(page).to have_content "Pending"
        expect(page).to have_content "Bank account ending in 6789"
      end
    end

    context 'after a payment has been made with credit card', :vcr, :stripe_mock, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryGirl.create(:user_with_all_documents_signed_and_credit_card, email: 'test@test.com')
        FactoryGirl.create(:payment_with_credit_card, amount: 600_00, student: student)
        login_as(student, scope: :student)
        visit student_payments_path(student)
        expect(page).to have_content 618.21
        expect(page).to have_content "Succeeded"
        expect(page).to have_content "Credit card ending in 4242"
      end
    end

    context 'with upfront payment due using a bank account', :vcr do
      it 'only shows a link to make an upfront payment with correct amount' do
        plan = FactoryGirl.create(:upfront_payment_only_plan, upfront_amount: 200_00)
        student = FactoryGirl.create(:user_with_verified_bank_account, email: 'test@test.com', plan: plan)
        login_as(student, scope: :student)
        visit student_payments_path(student)
        expect(page).to have_button('Make upfront payment of $200.00')
      end
    end

    context 'with upfront payment due using a credit card', :stripe_mock do
      it 'only shows a link to make an upfront payment with correct amount' do
        plan = FactoryGirl.create(:upfront_payment_only_plan, upfront_amount: 200_00)
        student = FactoryGirl.create(:user_with_credit_card, plan: plan)
        login_as(student, scope: :student)
        visit student_payments_path(student)
        expect(page).to have_button('Make upfront payment of $206.27')
      end
    end
  end

  context 'as an admin' do
    let(:admin) { FactoryGirl.create(:admin) }
    before { login_as(admin, scope: :admin) }

    scenario "for a student without a primary payment method" do
      student = FactoryGirl.create(:user_with_all_documents_signed)
      visit student_payments_path(student)
      expect(page).to have_content "Payments for #{student.name}"
      expect(page).to have_content "No payments have been made yet."
      expect(page).to have_content "No primary payment method has been selected."
    end

    context 'before any payments have been made', :stripe_mock do
      it "doesn't show payment history" do
        student = FactoryGirl.create(:user_with_credit_card)
        visit student_payments_path(student)
        expect(page).to have_content "No payments have been made yet."
      end
    end

    context 'after a payment has been made with bank account', :vcr, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryGirl.create(:user_with_all_documents_signed_and_verified_bank_account, email: 'test@test.com')
        payment = FactoryGirl.create(:payment_with_bank_account, amount: 600_00, student: student)
        visit student_payments_path(student)
        expect(page).to have_content 600.00
        expect(page).to have_content "Pending"
        expect(page).to have_content "Bank account ending in 6789"
        expect(page).to have_css "#refund-#{payment.id}-button"
      end
    end

    context 'after a payment has been made with credit card', :vcr, :stripe_mock, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryGirl.create(:user_with_all_documents_signed_and_credit_card, email: 'test@test.com')
        payment = FactoryGirl.create(:payment_with_credit_card, amount: 600_00, student: student)
        visit student_payments_path(student)
        expect(page).to have_content 618.21
        expect(page).to have_content "Succeeded"
        expect(page).to have_content "Credit card ending in 4242"
        expect(page).to have_css "#refund-#{payment.id}-button"
      end
    end

    context 'after a refund has been issued to a bank account payment', :vcr, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryGirl.create(:user_with_all_documents_signed_and_verified_bank_account, email: 'test@test.com')
        payment = FactoryGirl.create(:payment_with_bank_account, amount: 600_00, student: student)
        payment.update(refund_amount: 300_00)
        visit student_payments_path(student)
        expect(page).to have_content '$300.00'
      end
    end

    context 'after a refund has been issued to a credit card payment', :vcr, :stub_mailgun do
      it 'shows payment history with correct charge and status' do
        student = FactoryGirl.create(:user_with_all_documents_signed_and_credit_card, email: 'test@test.com')
        payment = FactoryGirl.create(:payment_with_credit_card, amount: 600_00, student: student)
        payment.update(refund_amount: 200_00)
        visit student_payments_path(student)
        expect(page).to have_content '$200.00'
      end
    end

    scenario 'via search', :vcr, :stub_mailgun do
      student = FactoryGirl.create(:user_with_all_documents_signed_and_credit_card, email: 'test@test.com')
      payment = FactoryGirl.create(:payment_with_credit_card, student: student)
      visit root_path
      fill_in 'search', with: 'test@test.com'
      click_on 'student-search'
      click_on 'Manage payments'
      expect(page).to have_content "Payments for #{student.name}"
    end
  end
end

feature 'issuing a refund as an admin', :vcr, :stub_mailgun do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:student) { FactoryGirl.create(:user_with_all_documents_signed_and_credit_card, email: 'test@test.com') }
  let!(:payment) { FactoryGirl.create(:payment_with_credit_card, amount: 100_00, student: student) }

  before { login_as(admin, scope: :admin) }

  scenario 'successfully without cents' do
    visit student_payments_path(student)
    fill_in "refund-#{payment.id}-input", with: 60
    click_on 'Refund'
    expect(page).to have_content "Refund successfully issued for #{payment.student.name}."
    expect(page).to have_content '$60.00'
  end

  scenario 'successfully with cents' do
    visit student_payments_path(student)
    fill_in "refund-#{payment.id}-input", with: 60.18
    click_on 'Refund'
    expect(page).to have_content "Refund successfully issued for #{payment.student.name}."
    expect(page).to have_content '$60.18'
  end

  scenario 'unsuccessfully with an improperly formatted amount', :js do
    visit student_payments_path(student)
    fill_in "refund-#{payment.id}-input", with: 60.1
    message = accept_prompt do
      click_on 'Refund'
    end
    expect(message).to eq 'Please enter an amount that includes 2 decimal places.'
  end

  scenario 'unsuccessfully with an amount that is too large' do
    visit student_payments_path(student)
    fill_in "refund-#{payment.id}-input", with: 200
    click_on 'Refund'
    expect(page).to have_content 'Refund amount ($200.00) is greater than charge amount ($103.28)'
  end

  scenario 'unsuccessfully with a negative amount' do
    visit student_payments_path(student)
    fill_in "refund-#{payment.id}-input", with: -16.46
    click_on 'Refund'
    expect(page).to have_content 'Invalid positive integer'
  end
end

feature 'make a manual payment' do

  scenario 'successfully with cents' do
    visit student_payments_path(student)
    fill_in :amount, with: 1765.24
    click_on 'Manual Payment'
    expect(page).to have_content "Manual payment successfully made for #{@student.name}."
    expect(page).to have_content '$1765.24'
  end

  scenario 'successfully without cents' do
    visit student_payments_path(student)
    fill_in :amount, with: 1765
    click_on 'Manual Payment'
    expect(page).to have_content "Manual payment successfully made for #{@student.name}."
    expect(page).to have_content '$1765.00'
  end

  scenario 'unsuccessfully with an improperly formatted amount' do
    visit student_payments_path(student)
    fill_in :amount, with: 60.1
    message = accept_prompt do
      click_on 'Manual Payment'
    end
    expect(message).to eq 'Please enter an amount that includes 2 decimal places.'
  end

  scenario 'unsuccessfully with an amount that is too large' do
    visit student_payments_path(student)
    fill_in :amount, with: 5100
    click_on 'Manual Refund'
    expect(page).to have_content 'Value must be less than or equal to $5000.00.'
  end

  scenario 'unsuccessfully with a negative amount' do
    visit student_payments_path(student)
    fill_in :amount, with: -16.46
    click_on 'Manual Payment'
    expect(page).to have_content 'Invalid positive integer'
  end

  scenario 'no primary payment method selected' do
    visit student_payments_path(student)
    expect(page).to have_content 'No primary payment method has been selected.'
  end

  context 'after a manual payment is made' do
    it 'the payment shows up in the payment history with the proper status and amount' do
      visit student_payments_path(student)
      fill_in :amount, with: 2500
      click_on 'Manual Refund'
      expect(page).to have_content 'Pending'
      expect(page).to have_content '$2500.00'
    end
  end



end
