class ItemsController < ApplicationController
  before_action :set_item , only: [:show, :buy, :edit, :destroy]
  before_action :move_to_index, only: [:edit, :destroy]
  before_action :not_buy, only: [:buy]
  before_action :authenticate_user! ,only: [:buy, :pay, :done]
  
  require "payjp"

  def buy #クレジット購入
      card = CreditCard.where(user_id: current_user.id).first
      @item = Item.find(params[:id])
      @image = ItemImage.where(item_id: @item.id).first
      if card.present?
      Payjp.api_key = ENV["PAYJP_PRIVATE_KEY"]
      customer = Payjp::Customer.retrieve(card.customer_id)
      @default_card_information = customer.cards.retrieve(card.card_id)
      end
  end

  def pay
      @item = Item.find(params[:id])
      card = CreditCard.where(user_id: current_user.id).first
      if card.blank?
        redirect_to new_credit_card_path 
      else
      Payjp.api_key = ENV['PAYJP_PRIVATE_KEY']
      Payjp::Charge.create(
      amount: @item.price, 
      customer: card.customer_id, 
      currency: 'jpy',
      )
      end
        redirect_to done_item_path(@item.id) 
  end

  def done
    @item = Item.find(params[:id])
    @item.update(buyer_id: current_user.id)
  
  def index
  end
  
  def show
    @item = Item.find(params[:id])
    @user = User.where(id: @item.exhibitor_id).first
    @address = Address.where(id: @user.id).first
    @parent = @item.category
  end
  
  
  def create
    @item = Item.new(item_params)
  end
  
  def edit
  end
  
  def destroy
    if @item.destroy
      redirect_to root_path
    else
      render :show, alert: '削除に失敗しました。'
    end
  end
  
  def update
  end
  
  def new
    binding.pry
    @item = Item.new

  end
  
  def get_category_children
    @category_children = Category.find_by(id: "#{params[:parent_name]}", ancestry: nil).children
  end

  def get_category_grandchildren
    @category_grandchildren = Category.find("#{params[:child_id]}").children
  end

  def get_item_size
    selected_grandchild = Category.find("#{params[:grandchild_id]}")
    if related_size_parent = selected_grandchild.item_sizes[0]
      @item_sizes = related_size_parent.children
    else
      selected_child = Category.find("#{params[:grandchild_id]}").parent
      if related_size_parent = selected_child.item_sizes[0]
          @item_sizes = related_size_parent.children
      end
    end
  end

  private

  def item_params
    #ItemModelでインクルードしたモジュールメソッドを使う(他のモデルで流用可能)
    reject = %w(buyer_id)
    columns = Item.column_symbolized_names(reject)
    params.require(:item).permit(*columns)
  end


  
  def category_index
  end
  
  private
  def set_item
    @item = Item.find(params[:id])
  end
  
  def not_buy
    if current_user.id == @item.exhibitor_id
      redirect_to root_path
    end
  end
  
  def move_to_index
    if !user_signed_in?
      redirect_to root_path
    elsif current_user.id!=@item.exhibitor_id
        redirect_to root_path
    end
  end

  def item_params
    #ItemModelでインクルードしたモジュールメソッドを使う(他のモデルで流用可能)
    reject = %w(category_id ,buyer_id)
    columns = Item.column_symbolized_names(reject).push(category_id: []) #category_idを配列で追加
    params.require(:item).permit(*columns)
  end


end


