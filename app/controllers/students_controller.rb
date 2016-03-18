class StudentsController < ApplicationController
  authorize_resource

  def index
    if params[:search]
      @query = params[:search]
      @results = Student.includes(:courses).search(@query)
      render 'search_results'
    elsif params[:course_id]
      @course = Course.find(params[:course_id])
      @enrollment = Enrollment.new
    else
      redirect_to root_path
    end
  end

  def show
    @student = Student.find(params[:id])
    @course = Course.find(params[:course_id])
    authorize! :read, @student
  end

  def update
    if current_admin
      @student = Student.find(params[:id])
      if @student.update(student_params)
        redirect_to course_student_path(@student.course, @student), notice: "Courses for #{@student.name} have been updated"
      else
        @course = Course.find(params[:student][:course_id])
        render 'show'
      end
    elsif current_student
      if current_student.update(student_params)
        if request.referer.include?('payment_methods')
          redirect_to :back, notice: "Primary payment method has been updated."
        else
          redirect_to :back, notice: "Internship ratings have been updated."
        end
      else
        if request.referer.include?('internships')
          @course = Course.find(Rails.application.routes.recognize_path(request.referrer)[:course_id])
          render 'internships/index'
        else
          @payments = current_student.payments
          render 'payments/index'
        end
      end
    end
  end

private
  def student_params
    params.require(:student).permit(:primary_payment_method_id,
                                    :course_id,
                                    ratings_attributes: [:id, :interest, :internship_id, :notes])
  end
end
