class ItemsController < ApplicationController
  include CommonModuleForControllers
  before_action :set_item , only: [:update,:show, :buy, :edit, :destroy, :pay, :evaluate, :evaluate_delete]
  before_action :move_to_index, only: [:edit, :destroy]
  before_action :authenticate_user! ,only: [:buy, :pay, :new, :edit, :evaluate]
  before_action :not_buy, only: [:buy]
  before_action :set_prefecture, only: [:show, :edit, :update]
  before_action :set_card, only: [:buy, :pay]
  before_action :sold_out, only: [:buy, :pay]
  before_action :set_category
  
  require "payjp"

  def evaluate_delete
    if @item.purchaser_id_status == current_user.id
      if @item.update( purchaser_id_status: nil)
        redirect_to item_path(@item.id), alert: "出品者の評価を取り消しました"
      else
        redirect_to item_path(@item.id), alert: "出品者評価を取り消しできません"
      end
    else
      redirect_to item_path(@item.id), alert: "購入者のみが出品者評価を取り消しできます"
    end
  end

  def evaluate
    if @item.purchaser_id == current_user.id
      if @item.update( purchaser_id_status: @item.purchaser_id)
        redirect_to item_path(@item.id), alert: "出品者を評価しました"
      else
        redirect_to item_path(@item.id), alert: "出品者を評価できません"
      end
    else
      redirect_to item_path(@item.id), alert: "購入者のみが出品者を評価できます"
    end
  end

  def buy #クレジット購入
    @image = ItemImage.where(item_id: @item.id).first
    if @card.present?
      Payjp.api_key = ENV["PAYJP_PRIVATE_KEY"]
      customer = Payjp::Customer.retrieve(@card.customer_id)
      @default_card_information = customer.cards.retrieve(@card.card_id)
    end
  end

  def pay
      if @card.blank?
        redirect_to new_credit_card_path 
      else
        Payjp.api_key = ENV['PAYJP_PRIVATE_KEY']
        Payjp::Charge.create(
        amount: @item.price, 
        customer: @card.customer_id, 
        currency: 'jpy',
        )
      end
      @item.purchaser_id = current_user.id
      if @item.update( purchaser_id: current_user.id)
        redirect_to root_path , notice: '購入完了しました'
      else
        redirect_to item_path(@item.id), alert: "購入に失敗しました"
      end
  end

  def index
    @items = Item.all.includes(:user)
    has_brand_items = Item.where.not(brand: nil)
    if has_brand_items.sample != nil
      @pickup_brand = has_brand_items.sample.brand
    end
    @pickup_items = Item.where(brand: @pickup_brand)
  end

  def show
    @item_images = @item.item_images
    @exhibitor = User.where(id: @item.exhibitor_id).first
    @purchaser = User.where(id: @item.purchaser_id).first
    @image = ItemImage.where(item_id: @item.id).first
    @parent = @item.category
    @comment = Comment.new
    @comments = @item.comments.includes(:user)
  end


  def create
    if params[:item][:item_images_attributes] != nil?
      @item = Item.new(item_params.merge(exhibitor_id: current_user.id))
      @category = Category.where(ancestry: nil).order("id ASC").limit(13)
        if @item.save
          redirect_to root_path
        else
          redirect_to new_item_path, alert: '商品の出品に失敗しました'
        end
    else
      redirect_to new_item_path, alert: 'ERROR'
    end
  end

  def edit
    selected_grandchild = @item.category
    if related_size_parent = selected_grandchild.item_sizes[0]
      @item_sizes = related_size_parent.children
    else
      selected_child = @item.category.parent
      if related_size_parent = selected_child.item_sizes[0]
        @item_sizes = related_size_parent.children
      end
    end
  end
  
  def destroy
    if @item.destroy
      redirect_to root_path
    else
      render :show
    end
  end
  
  def update
    if @item.update(item_params)
      
      redirect_to root_path, notice: '編集完了しました'
    else 
      redirect_to edit_item_path, alert: '商品の編集に失敗しました'
    end
  end

  def new
    @item = Item.new
    @item.item_images.new
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

  def get_item_fee
  end

  def search #商品検索機能
    @items = Item.search(params[:keyword])
  end

  def search #商品検索機能
    @keyword = search_params[:name_cont]
  end

  def set_category
    @parents = Category.where(ancestry: nil).order("id ASC").limit(13)
  end


  private

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
    reject = %w()
    columns = Item.column_symbolized_names(reject).push(item_images_attributes: [ :id ,:image ,:_destroy]).push(:prefecture_id)
    params.require(:item).permit(*columns)
  end

  def set_card
    @card = CreditCard.where(user_id: current_user.id).first
  end

  def search_params
    params.require(:q).permit(:name_cont,:brand_cont,:price_gteq,:price_lteq,:status_cont)
  end

  def sold_out
    @item = Item.find(params[:id])
    if @item.purchaser_id.present?
      redirect_to root_path
    end
  end

end


