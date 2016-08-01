class CodeReviewCopiesController < ApplicationController
  def create
    code_review = CodeReview.find(params[:code_review][:id])
    copy_code_review = code_review.duplicate_code_review(current_course)
    if copy_code_review.save
      flash[:notice] = "Code review successfully copied."
      redirect_to course_path(current_course)
    end
  end
end
