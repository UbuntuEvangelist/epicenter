feature 'requesting a meeting' do
  context 'visiting as a student' do
    let(:admin) { FactoryBot.create(:admin) }
    let(:course) { FactoryBot.create(:course, admin: admin) }
    let(:student) { FactoryBot.create(:student, course: course) }
    let!(:submission) { FactoryBot.create(:submission, student: student)}
    before do
      login_as(student, scope: :student)
      visit new_course_meeting_path(course)
    end

    it 'shows page to request a meeting' do
      expect(page).to have_content("I'd like to request a meeting with a teacher this week.")
    end

    it 'sends email when explanation >= 50 characters' do
      allow(EmailJob).to receive(:perform_later).and_return({})
      fill_in 'teacher-meeting-explanation', with: '12345678901234567890123456789012345678901234567890'
      click_on 'Submit'
      expect(EmailJob).to have_received(:perform_later).with(
        { :from => ENV['FROM_EMAIL_REVIEW'],
          :to => student.course.admin.email,
          :subject => "Meeting request for: #{student.name}",
          :text => "12345678901234567890123456789012345678901234567890" }
      )
      expect(page).to have_content("Attendance")
    end

    it 'creates meeting_request note' do
      allow(EmailJob).to receive(:perform_later).and_return({})
      fill_in 'teacher-meeting-explanation', with: '12345678901234567890123456789012345678901234567890'
      click_on 'Submit'
      expect(submission.meeting_request_notes.last.content).to eq '12345678901234567890123456789012345678901234567890'
    end

    it 'attaches meeting_request note to latest submission only' do
      allow(EmailJob).to receive(:perform_later).and_return({})
      new_submission = FactoryBot.create(:submission, student: student)
      fill_in 'teacher-meeting-explanation', with: '12345678901234567890123456789012345678901234567890'
      click_on 'Submit'
      expect(submission.meeting_request_notes.count).to eq 0
      expect(new_submission.meeting_request_notes.count).to eq 1
    end

    it 'does not send email when not requested' do
      allow(EmailJob).to receive(:perform_later).and_return({})
      expect(EmailJob).to_not receive(:perform_later)
      click_on 'No thanks'
      expect(page).to have_content("Attendance")
    end
  end

  context 'visiting as an admin' do
    let(:admin) { FactoryBot.create(:admin) }
    let(:course) { FactoryBot.create(:course, admin: admin) }
    let(:student) { FactoryBot.create(:student, course: course) }
    let(:submission) { FactoryBot.create(:submission, student: student)}
    let!(:note) { FactoryBot.create(:meeting_request_note, submission: submission)}
    before do
      login_as(admin, scope: :admin)
      visit new_submission_review_path(submission)
    end

    it 'shows meeting request note on cr review page' do
      expect(page).to have_content 'Student meeting request notes'
    end

    it 'clears meeting request notes on meeting fulfilled', :js do
      click_on 'meeting fulfilled'
      accept_js_alert
      expect(page).to_not have_content 'Student meeting request notes'
    end
  end

  context 'visiting as a company' do
    it 'is not authorized' do
      course = FactoryBot.create(:course)
      company = FactoryBot.create(:company)
      login_as(company, scope: :company)
      visit new_course_meeting_path(course)
      expect(page).to have_content("not authorized")
    end
  end
end
