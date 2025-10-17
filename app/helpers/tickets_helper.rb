module TicketsHelper
  def ticket_status_text(ticket)
    case ticket.status.to_sym
    when :unused
      "未使用"
    when :used
      "已使用"
    when :expired
      "已過期"
    else
      "未知"
    end
  end

  def status_badge_class(ticket)
    case ticket.status.to_sym
    when :unused
      "bg-green-100 text-green-800"
    when :used
      "bg-gray-100 text-gray-800"
    when :expired
      "bg-red-100 text-red-800"
    else
      "bg-gray-100 text-gray-600"
    end
  end
  def ticket_card_class(ticket)
    if ticket.expired_or_overdue?
      "border-red-300 bg-red-50"
    elsif ticket.used?
      "border-gray-300 bg-gray-50"
    else
      "border-green-300 bg-white"
    end
  end
  def format_price(price)
    "NT$ #{price.to_i}"
  end
end
