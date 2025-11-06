defmodule HanaShirabeWeb.HanaIcon do
  # 一些图标
  # AI 搓的

  use Phoenix.Component
  use Gettext, backend: HanaShirabeWeb.Gettext

  def hana_icon(assigns),
    do: ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-width="1.5"
      stroke-linecap="round"
      stroke-linejoin="round"
    >
      <!-- 像素化的花瓣轮廓 -->
      <path d="M12 3 L14 4 L16 6 L16 8 L16 10 L15 11 L16 12 L18 12 L20 14 L21 16 L21 18 L20 20 L18 21 L16 21 L14 20 L12 18 L10 20 L8 21 L6 21 L4 20 L3 18 L3 16 L4 14 L6 12 L8 12 L9 11 L8 10 L8 8 L8 6 L10 4 Z" />
      <!-- 花心的音符 -->
      <circle cx="12" cy="14" r="1.5" fill="currentColor" />
      <path d="M13.5 14 V 7.5 C 13.5 6.5 15 6 17 9" />
    </svg>
    """

  def investigation(assigns),
    do: ~H"""
    <!-- investigation.svg -->
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.5"
      stroke-linecap="round"
      stroke-linejoin="round"
    >
      <!-- 放大镜手柄 -->
      <path d="M15.5 15.5 L21 21" />
      <!-- 放大镜外框 -->
      <circle cx="10" cy="10" r="7" />
      <!-- 镜中的依赖图谱 -->
      <circle cx="10" cy="10" r="0.5" fill="currentColor" />
      <circle cx="8" cy="8" r="0.5" fill="currentColor" />
      <circle cx="12" cy="8" r="0.5" fill="currentColor" />
      <circle cx="8" cy="12" r="0.5" fill="currentColor" />
      <circle cx="12" cy="12" r="0.5" fill="currentColor" /> <path d="M10 10 L8 8" stroke-width="1" />
      <path d="M10 10 L12 8" stroke-width="1" /> <path d="M10 10 L8 12" stroke-width="1" />
      <path d="M10 10 L12 12" stroke-width="1" />
    </svg>
    """

  def archive(assigns),
    do: ~H"""
    <!-- archive.svg -->
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.5"
      stroke-linecap="round"
      stroke-linejoin="round"
    >
      <!-- 档案盒主体 -->
      <path d="M4 20 L4 8 L12 2 L20 8 L20 20 L4 20 Z" /> <path d="M4 8 L20 8" />
      <path d="M12 2 L12 8" />
      <!-- 盒中的时间轴 -->
      <path d="M7 14 L17 14" /> <circle cx="8" cy="14" r="0.5" fill="currentColor" />
      <circle cx="12" cy="14" r="0.5" fill="currentColor" />
      <circle cx="16" cy="14" r="0.5" fill="currentColor" />
      <!-- 右下角的“重新激活”符号 -->
      <path d="M18.5 16 A 1.5 1.5 0 0 1 17 17.5 L17 17.5 A 1.5 1.5 0 0 1 15.5 16" />
      <path d="M15.5 17.5 L15.5 18 L16.5 19" />
    </svg>
    """
end
