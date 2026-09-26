package mmo.petfightnew.common.panel
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.interfaces.IDispose;
   import mmo.petfightnew.common.FightItemData;
   import mmo.petfightnew.common.panel.item.NewItemHolder;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1750")]
   public class ItemPanel extends UIPanelBase implements IDispose
   {
      
      public var btnLeft:SimpleButton;
      
      public var btnRight:SimpleButton;
      
      public var hd0:TextField;
      
      public var hd1:TextField;
      
      public var hd2:TextField;
      
      public var hd3:TextField;
      
      public var hd4:TextField;
      
      public var hd5:TextField;
      
      public var tipsPanel:MovieClip;
      
      public var txtPage:TextField;
      
      private const PAGE_ITEM_NUM:int = 6;
      
      private var _myFightItems:Array;
      
      private var _curPageIndex:int = 0;
      
      private var _totalPage:int;
      
      private var _btnLeft:SimpleButton;
      
      private var _btnRight:SimpleButton;
      
      private var _mcTipsPanel:Sprite;
      
      private var _itemHolderList:Array = [];
      
      private var _txtPage:TextField;
      
      public function ItemPanel()
      {
         super();
         this._myFightItems = FightItemData.instance.myFightItems;
         this._totalPage = Math.max(1,Math.ceil(this._myFightItems.length / this.PAGE_ITEM_NUM));
         this._mcTipsPanel = this.getChild("tipsPanel");
         this._mcTipsPanel.mouseEnabled = this._mcTipsPanel.mouseChildren = false;
         this._mcTipsPanel.visible = this._myFightItems.length <= 0;
         this._txtPage = this.getChild("txtPage");
         this._txtPage.mouseEnabled = false;
         this._btnLeft = this.getChild("btnLeft");
         this._btnLeft.addEventListener(MouseEvent.CLICK,this.onLeft);
         this._btnRight = this.getChild("btnRight");
         this._btnRight.addEventListener(MouseEvent.CLICK,this.onRight);
         this.update();
      }
      
      private function getChild(param1:String) : *
      {
         return this.getChildByName(param1);
      }
      
      override public function update() : void
      {
         var _loc2_:NewItemHolder = null;
         var _loc4_:Object = null;
         var _loc5_:TextField = null;
         var _loc6_:int = 0;
         this._txtPage.text = this._curPageIndex + 1 + "/" + this._totalPage;
         var _loc1_:int = this._curPageIndex * this.PAGE_ITEM_NUM;
         var _loc3_:int = 0;
         while(_loc3_ < this.PAGE_ITEM_NUM)
         {
            _loc2_ = this._itemHolderList[_loc3_];
            _loc4_ = this._myFightItems[_loc1_ + _loc3_];
            if(_loc4_ == null)
            {
               if(_loc2_ != null)
               {
                  _loc2_.visible = false;
               }
            }
            else
            {
               if(_loc2_ == null)
               {
                  _loc5_ = this.getChild("hd" + _loc3_);
                  _loc5_.mouseEnabled = false;
                  _loc6_ = this.getChildIndex(_loc5_);
                  this._itemHolderList[_loc3_] = _loc2_ = new NewItemHolder();
                  _loc2_.x = _loc5_.x;
                  _loc2_.y = _loc5_.y;
                  this.addChildAt(_loc2_,_loc6_);
               }
               else
               {
                  _loc2_.visible = true;
               }
               _loc2_.update(_loc4_);
            }
            _loc3_++;
         }
      }
      
      override public function dispose() : void
      {
         var _loc1_:NewItemHolder = null;
         for each(_loc1_ in this._itemHolderList)
         {
            _loc1_.dispose();
         }
         this._itemHolderList = null;
         this._myFightItems = null;
         this._btnLeft.removeEventListener(MouseEvent.CLICK,this.onLeft);
         this._btnRight.removeEventListener(MouseEvent.CLICK,this.onRight);
      }
      
      private function onLeft(param1:MouseEvent) : void
      {
         if(this._curPageIndex > 0)
         {
            --this._curPageIndex;
            this.update();
         }
      }
      
      private function onRight(param1:MouseEvent) : void
      {
         if(this._curPageIndex < this._totalPage - 1)
         {
            ++this._curPageIndex;
            this.update();
         }
      }
   }
}

