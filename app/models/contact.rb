class Contact < ApplicationRecord
  PRIMARY_CONTACT = "primary"
  SECONDARY_CONTACT = "secondary"

  def self.create_or_update_contact(params)
    email = params[:email]
    phone_number = params[:phone_number]

    contacts = fetch_contacts(email, phone_number)
    

    contacts = if contacts.empty?
                 contact = Contact.create(
                   email: email,
                   phone_number: phone_number,
                   link_precedence: PRIMARY_CONTACT
                 )
                 [contact]
               else
                 check_and_create_linkage(contacts).to_a
               end

    generate_response(contacts)
  end

  def self.fetch_contacts(email, phone_number)
    if email.present? && phone_number.present?
      Contact.where(email: email, phone_number: phone_number).order('id')
    elsif email.present?
      Contact.where(email: email).order('id')
    elsif phone_number.present?
      Contact.where(phone_number: phone_number).order('id')
    end
  end

  def self.check_and_create_linkage(contacts)
    return contacts if contacts.where(link_precedence: PRIMARY_CONTACT).count == 1
    first_contact = contacts.first
    contacts.where(id: contacts.ids - [first_contact.id])
            .update(link_precedence: SECONDARY_CONTACT, linked_id: first_contact.id)
  end

  def self.generate_response(records)
    primary_contact_id = nil
    emails = []
    phone_numbers = []
    secondary_contact_ids = []

    records.each do |record|
      primary_contact_id = record.id if record.link_precedence == PRIMARY_CONTACT
      emails << record.email if record.email.present?
      phone_numbers << record.phone_number if record.phone_number.present?
      secondary_contact_ids << record.id if record.link_precedence == SECONDARY_CONTACT
    end

    {
      "contact": {
        "primary_contact_id": primary_contact_id,
        "emails": emails.uniq,
        "phone_numbers": phone_numbers.uniq,
        "secondary_contact_ids": secondary_contact_ids.uniq
      }
    }
  end
end