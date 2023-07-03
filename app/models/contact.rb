class Contact < ApplicationRecord
  PRIMARY_CONTACT = "primary"
  SECONDARY_CONTACT = "secondary"

  def self.create_or_update_contact(params)
    email = params[:email]
    phone_number = params[:phoneNumber]

    check_and_create_contact(email, phone_number)
    check_and_create_contact_linkages(fetch_contacts(email, phone_number))

    generate_response(fetch_contacts(email, phone_number))
  end

  def self.check_and_create_contact(email, phone_number)
    contact_via_email = Contact.where(email: email) if email.present?
    contact_via_phone_number = Contact.where(phone_number: phone_number) if phone_number.present?
    if email.present? && phone_number.present? && (contact_via_email.empty? || contact_via_phone_number.empty?)
      Contact.create(
        email: email,
        phone_number: phone_number,
        link_precedence: PRIMARY_CONTACT
      )
    elsif email.present? && contact_via_email.empty?
      Contact.create(
        email: email,
        link_precedence: PRIMARY_CONTACT
      )
    elsif phone_number.present? && contact_via_phone_number.empty?
      Contact.create(
        phone_number: phone_number,
        link_precedence: PRIMARY_CONTACT
      )
    end
  end

  def self.fetch_contacts(email, phone_number)
    conditions = []
    email_list = [email].compact
    phone_number_list = [phone_number].compact
    new_email_list = []
    new_phone_number_list = []
    contacts = nil

    while true
      contacts = if email_list.present? && phone_number_list.present?
                   Contact.where(email: email_list).or(Contact.where(phone_number: phone_number_list))
                 elsif email_list.present?
                   Contact.where(email: email_list)
                 elsif phone_number_list.present?
                   Contact.where(phone_number: phone_number_list)
                 end
      new_email_list = contacts.pluck(:email).uniq
      new_phone_number_list = contacts.pluck(:phone_number).uniq
      break if new_email_list == email_list && new_phone_number_list == phone_number_list
      email_list = new_email_list
      phone_number_list = new_phone_number_list
    end

    contacts
  end

  def self.check_and_create_contact_linkages(contacts)
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
    linked_ids = records.pluck(:linked_id)

    records.each do |record|
      primary_contact_id = record.id if record.link_precedence == PRIMARY_CONTACT
      emails << record.email if record.email.present?
      phone_numbers << record.phone_number if record.phone_number.present?
      secondary_contact_ids << record.id if record.link_precedence == SECONDARY_CONTACT
    end

    while primary_contact_id.nil?
      new_records = Contact.where(id: linked_ids)
      new_records.each do |record|
        primary_contact_id = record.id if record.link_precedence == PRIMARY_CONTACT
        emails << record.email if record.email.present?
        phone_numbers << record.phone_number if record.phone_number.present?
        secondary_contact_ids << record.id if record.link_precedence == SECONDARY_CONTACT
      end
      linked_ids = new_records.pluck(:linked_id)
    end

    {
      "contact": {
        "primaryContactId": primary_contact_id,
        "emails": emails.uniq,
        "phoneNumbers": phone_numbers.uniq,
        "secondaryContactIds": secondary_contact_ids.uniq
      }
    }
  end
end