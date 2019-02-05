class CreditCardsController < ApplicationController
  authorize_resource

  def new
    @credit_card = CreditCard.new
  end

  def create
    @credit_card = CreditCard.new(credit_card_params.merge(student: current_student))
    if @credit_card.save
      redirect_to student_payments_path(current_student), notice: "Your credit card has been added but not yet charged."
    else
      render :new
    end
  end

private
  def credit_card_params
    params.require(:credit_card).permit(:stripe_token)
  end
end
