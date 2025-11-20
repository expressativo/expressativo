module UsersHelper
  def user_avatar(user, options = {})
    size = options[:size] || 8
    css_class = options[:class] || "w-#{size} h-#{size} rounded-full object-cover"

    if user.avatar.attached?
      image_tag(user.avatar, class: css_class, alt: user.full_name)
    else
      content_tag(:div, class: "#{css_class} bg-gradient-to-br from-purple-400 to-indigo-500 flex items-center justify-center") do
        content_tag(:span, class: "text-white font-bold text-#{size == 8 ? 'xs' : size == 32 ? '4xl' : 'sm'}") do
          "#{user.first_name&.first&.upcase}#{user.last_name&.first&.upcase}"
        end
      end
    end
  end
end
