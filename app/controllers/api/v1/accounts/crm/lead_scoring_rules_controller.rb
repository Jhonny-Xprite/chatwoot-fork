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
    Rails.logger.info "[CRM] Criando nova regra de lead scoring para conta #{current_account.id}: #{rule_params.inspect}"
    @rule = current_account.crm_lead_scoring_rules.new(rule_params)
    if @rule.save
      Rails.logger.info "[CRM] Regra ##{@rule.id} criada com sucesso."
      render json: @rule, status: :created
    else
      Rails.logger.warn "[CRM] Falha ao criar regra de scoring: #{@rule.errors.full_messages}"
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
    Rails.logger.info "[CRM] Excluindo regra de scoring ##{@rule.id}"
    @rule.destroy
    Rails.logger.info "[CRM] Regra de scoring ##{@rule.id} removida."
    head :no_content
  end

  def recalculate
    count = current_account.contacts.count
    Rails.logger.info "[CRM] Iniciando recálculo massivo de Lead Scoring para #{count} contatos da conta #{current_account.id}."
    current_account.contacts.find_each do |contact|
      Crm::LeadScoringCalculationJob.perform_later(contact.id)
    end
    render json: { message: 'Recalculation started' }, status: :ok
  end

  private

  def set_rule
    @rule = current_account.crm_lead_scoring_rules.find(params[:id])
  end

  def rule_params
    params.require(:lead_scoring_rule).permit(:attribute_model, :attribute_key, :filter_operator, :score, values: [])
  end
end
