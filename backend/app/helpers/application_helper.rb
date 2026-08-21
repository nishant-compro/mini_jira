module ApplicationHelper
  def avatar_for(user, size: 22, accent: false)
    return content_tag(:div, "", class: "avatar", style: "width:#{size}px;height:#{size}px;") unless user

    classes = [ "avatar" ]
    classes << "avatar--accent" if accent
    font_size = size <= 24 ? 10 : 11

    content_tag(:div, user.initials, class: classes.join(" "),
                style: "width:#{size}px;height:#{size}px;font-size:#{font_size}px;")
  end

  def type_badge(ticket)
    type = ticket.respond_to?(:ticket_type) && ticket.ticket_type.present? ? ticket.ticket_type : "task"
    content_tag(:span, type.humanize, class: "badge badge--#{type}")
  end

  def status_badge(ticket)
    label = ticket.status == "in_progress" ? "In progress" : ticket.status.humanize
    content_tag(:span, label, class: "badge badge--status-#{ticket.status}")
  end

  def project_icon_tile(project)
    content_tag(:div, icon(:folder), class: "icon-tile")
  end

  def icon(name, size: 16)
    icons = {
      folder: '<path d="M3 5.5A1.5 1.5 0 0 1 4.5 4h3.379a1.5 1.5 0 0 1 1.06.44l1.122 1.12A1.5 1.5 0 0 0 11.12 6H19.5A1.5 1.5 0 0 1 21 7.5v10A1.5 1.5 0 0 1 19.5 19h-15A1.5 1.5 0 0 1 3 17.5v-12Z" />',
      chevron_right: '<path d="M9 5l7 7-7 7" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
      plus: '<path d="M12 5v14M5 12h14" fill="none" stroke-width="2" stroke-linecap="round" />',
      person: '<circle cx="12" cy="8" r="3.2" fill="none" stroke-width="1.6" /><path d="M5 20c1.2-3.6 4-5.4 7-5.4s5.8 1.8 7 5.4" fill="none" stroke-width="1.6" stroke-linecap="round" />',
      person_check: '<circle cx="10" cy="8" r="3.2" fill="none" stroke-width="1.6" /><path d="M3.5 20c1.1-3.4 3.7-5.2 6.5-5.2" fill="none" stroke-width="1.6" stroke-linecap="round" /><path d="M15.5 13.5l2 2 3.5-3.5" fill="none" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" />'
    }

    content_tag(:svg, icons[name].html_safe, xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 24 24",
                width: size, height: size, class: "icon", fill: "currentColor", stroke: "currentColor")
  end
end
# View helper definitions.
