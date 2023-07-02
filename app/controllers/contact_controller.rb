class ContactController < ApplicationController
  CREATE_OR_UPDATE_CONTACT_PARAMS = %i[email phone_number]

  def create_or_update_contact
    params.permit(CREATE_OR_UPDATE_CONTACT_PARAMS)
    response = Contact.create_or_update_contact(params)
    render json: response
  end
end