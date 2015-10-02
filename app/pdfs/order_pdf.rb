# -*- coding: utf-8 -*-
class OrderPDF < Prawn::Document
  def initialize(order)
    super()

    # 複数メソッドで利用できるようにするため
    # インスタンス変数に代入
    @spree_order = order

    # 全体のフォントを設定
    font "vendor/fonts/ipaexg.ttf"

    # ヘッダー部分の表示
    header
    # ヘッダーリード部分の表示
    header_lead

    address_lead

    signature_lead

    message_lead

    # テーブル部分の表示
    table_content
  end

  def header
    # size 28 で "Order"という文字を表示
    text "　　　　　　　　納品書", size: 28

    # stroke(線)の色を設定し、線を引く
    stroke_color "eeeeee"
    stroke_line [0, 680], [530, 680]
  end

  def header_lead
    # カーソルを指定
    y_position = cursor - 30

    # bounding_boxで記載箇所を指定して、textメソッドでテキストを記載
    bounding_box([400, y_position], :width => 270, :height => 50) do
      font_size 10.5
      text "注文番号:  #{@spree_order.number}"
      move_down 3
      text "　注文日:  #{@spree_order.created_at.strftime('%Y年%m月%d日')}"
    end
  end

  def address_lead
    # カーソルを指定
    y_position = cursor

    # bounding_boxで記載箇所を指定して、textメソッドでテキストを記載
    bounding_box([0, y_position], :width => 300, :height => 100) do
      font_size 10.5
      text "発送先"
      move_down 10
      text "〒 #{@spree_order.ship_address.zipcode}"
      move_down 3
      text "#{@spree_order.ship_address.state.name}#{@spree_order.ship_address.city}#{@spree_order.ship_address.address1}"
      move_down 3
      text "#{@spree_order.ship_address.address2}"
      move_down 3
      text "　　　　　　　　#{@spree_order.ship_address.lastname} #{@spree_order.ship_address.firstname} 様"
    end
  end

  def signature_lead
    # カーソルを指定
    y_position = cursor

    # bounding_boxで記載箇所を指定して、textメソッドでテキストを記載
    bounding_box([400, y_position], :width => 270, :height => 70) do
      font_size 10.5
      text "ニシムラモータース"
      move_down 5
      text "〒 900-0005"
      move_down 3
      text "沖縄県那覇市天久794-6 1F"
      move_down 3
      text "(098) 927-1503"
      move_down 3
      text "parts.nishimuramotors.com"
    end
  end

  def message_lead
    # カーソルを指定
    y_position = cursor

    # bounding_boxで記載箇所を指定して、textメソッドでテキストを記載
    bounding_box([0, y_position], :width => 520, :height => 50) do
      font_size 10.5
      text "ご注文誠にありがとうございました。"
    end
  end

  def table_content
    y_position = cursor

    bounding_box([0, y_position], :width => 520) do
      # tableメソッドは2次元配列を引数(line_item_rows)にとり、それをテーブルとして表示する
      # ブロック(do...end)内でテーブルの書式の設定をしている
      table line_item_rows do
        # 全体設定
        cells.padding = 8          # セルのpadding幅
        cells.borders = [:bottom,] # 表示するボーダーの向き(top, bottom, right, leftがある)
        cells.border_width = 0.5   # ボーダーの太さ

        # 個別設定
        # row(0) は0行目、row(-1) は最後の行を表す
        row(0).border_width = 1.5
        row(-2).border_width = 1.5
        # row(-1).background_color = "f0ad4e"
        row(-1).borders = []

        self.header     = true  # 1行目をヘッダーとするか否か
        self.row_colors = ['dddddd', 'ffffff'] # 列の色
        self.column_widths = [50, 200, 100, 70, 100] # 列の幅
      end
    end
  end

  # テーブルに表示するデータを作成(2次元配列)
  def line_item_rows
    # テーブルのヘッダ部
    arr = [["#", "品名", "単価", "数量", "値段"]]

    # テーブルのデータ部
    @line_items = Hash.new
    @spree_order.line_items.each do |item|
      @line_items.store(item.variant_id, {quantity: item.quantity, price: item.price})
    end

    @spree_order.products.map.with_index do |p, i|
      arr << [i+1,
              p.name,
              jpy_comma(@line_items[p.id][:price]),
              @line_items[p.id][:quantity],
              jpy_comma(@line_items[p.id][:price]* @line_items[p.id][:quantity])]
    end

    # テーブルの合計部
    arr << ["", "", "", "合計", "#{jpy_comma(@spree_order.item_total)} 円"]
    return arr
  end

  def jpy_comma(number)
    number.round.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\1,')
  end
end
