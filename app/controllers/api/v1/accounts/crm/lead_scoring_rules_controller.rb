class Api::V1::Accounts::Crm::LeadScoringRulesController < Api::V1::Accounts::BaseController
  before_action :set_rule, only: [:show, :update, :destroy]

  def index
    @rules = current_account.crm_lead_scoring_rules
    render json: @rules
  end

  def show
    render json: @rule
  end

  def create
    @rule = current_account.crm_lead_scoring_rules.new(rule_params)
    if @rule.save
      render json: @rule, status: :created
    else
      render json: @rule.errors, status: :unprocessable_entity
    end
  end

  def update
    if @rule.update(rule_params)
      render json: @rule
    else
      render json: @rule.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @rule.destroy
    head :no_content
  end

  private

  def set_rule
    @rule = current_account.crm_lead_scoring_rules.find(params[:id])
  end

  def rule_params
    params.require(:lead_scoring_rule).permit(:attribute_model, :attribute_key, :filter_operator, :score, values: [])
  end
end
