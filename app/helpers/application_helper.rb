module ApplicationHelper
  def cdata(str)
    "<![CDATA[\n  #{str.to_s.gsub!("\n", "\n  ") || str}\n]]>"
  end

  def analytics
    render(:partial => 'shared/analytics') if PRODUCTION
  end
end
