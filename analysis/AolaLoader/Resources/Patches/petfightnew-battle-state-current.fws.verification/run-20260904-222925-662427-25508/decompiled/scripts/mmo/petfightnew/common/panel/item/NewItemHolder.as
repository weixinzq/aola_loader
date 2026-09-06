package mmo.petfightnew.common.panel.item
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.material.item.Item;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.MCPetContainer;
   import mmo.petfightnew.common.event.FightEventDispatcher;
   import mmo.petfightnew.common.handler.ItemIconHandler;
   import mmo.petfightnew.common.manager.ServicePool;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1731")]
   public class NewItemHolder extends Sprite
   {
      
      private static const UNAVAILABLE_ITEMS:Array = [380];
      
      private static const XUAN_WU_RACE_IDS:Array = [10388,20388,30388,40388];
      
      public var mcIcon:MovieClip;
      
      public var txtNum:TextField;
      
      protected var _itemService:IItemService = ServicePool.instance.getService(IItemService);
      
      protected var _quantity:int;
      
      protected var _itemId:int;
      
      protected var _itemIconHandler:ItemIconHandler;
      
      protected var _txtNum:TextField;
      
      public function NewItemHolder()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         var _loc1_:MovieClip = this.getChild("mcIcon");
         this._itemIconHandler = new ItemIconHandler(_loc1_);
         this._txtNum = this.getChild("txtNum");
         this._txtNum.mouseEnabled = false;
         this.addEventListener(MouseEvent.CLICK,this.onClickItem);
      }
      
      public function dispose() : void
      {
         FightEventDispatcher.instance.removeEventListener(PetFightEvent.CANCEL_USE_ITEM,this.onCancelUseItem);
         this.removePetListen();
         this.removeClickListener();
         this.removeEventListener(MouseEvent.CLICK,this.onClickItem);
      }
      
      private function getChild(param1:String) : *
      {
         return this.getChildByName(param1);
      }
      
      public function update(param1:Object) : void
      {
         this._itemId = param1.id;
         this._quantity = param1.qt;
         this.itemQuantityModify();
         if(this.isUnavailableItem() && !this.isXuanWu())
         {
            DisplayUtil.applyGray(this);
            this.buttonMode = false;
         }
         else
         {
            DisplayUtil.clearGray(this);
            this.buttonMode = true;
         }
         this._txtNum.text = this._quantity.toString();
         this.refreshTips();
         this._itemIconHandler.setIcon(this._itemId);
      }
      
      private function itemQuantityModify() : void
      {
         var _loc1_:int = FightData.instance.myInfo.getWillUseItemNum(this._itemId);
         this._quantity = Math.max(0,this._quantity - _loc1_);
      }
      
      private function onCancelUseItem(param1:Event) : void
      {
         this.removeClickListener();
         this.removePetListen();
      }
      
      private function isUnavailableItem() : Boolean
      {
         if(UNAVAILABLE_ITEMS.indexOf(this._itemId) == -1)
         {
            return false;
         }
         return true;
      }
      
      private function isXuanWu() : Boolean
      {
         var _loc2_:PlayerBattleInfo = null;
         var _loc1_:Array = FightData.instance.opponents;
         for each(_loc2_ in _loc1_)
         {
            if(XUAN_WU_RACE_IDS.indexOf(_loc2_.myPets[0].raceId) != -1)
            {
               return true;
            }
         }
         return false;
      }
      
      private function refreshTips() : void
      {
         var _loc1_:Item = this._itemService.getItemById(this._itemId);
         var _loc2_:* = _loc1_.description;
         if(this._quantity <= 0)
         {
            _loc2_ += "\n-------------\n数量为0，不可使用。";
         }
         TipsManager.getInstance().replaceComplexTips(this,_loc1_.name,_loc2_,100,-90,9);
      }
      
      protected function onClickItem(param1:MouseEvent) : void
      {
         var _loc2_:int = 0;
         if(this.isUnavailableItem() && !this.isXuanWu())
         {
            return;
         }
         if(this._quantity <= 0)
         {
            return;
         }
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.CLICK_ITEM_HOLDER,{"itemholder":this}));
         FightEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.CLICK_ITEM_HOLDER,{"itemholder":this}));
         if(this.isXuanWu())
         {
            this.useItem(FightData.instance.vsSlot);
         }
         else
         {
            _loc2_ = int(FightData.instance.myInfo.operatingPlayer.slotId);
            if(FightData.instance.isMultiControl())
            {
               this.addClickListener();
            }
            else
            {
               this.useItem(_loc2_);
            }
         }
      }
      
      private function useItem(param1:int) : void
      {
         FightController.instance.useItem(this._itemId,param1);
      }
      
      private function addClickListener() : void
      {
         var _loc2_:PlayerBattleInfo = null;
         var _loc3_:MCPetContainer = null;
         var _loc1_:FightPanel = FightController.instance.fightPanel;
         for each(_loc2_ in FightData.instance.playerInfo)
         {
            if(FightData.instance.isMySide(_loc2_.locaId))
            {
               _loc3_ = _loc1_.petMCList[_loc2_.locaId];
               if(_loc1_.contains(_loc3_))
               {
                  _loc3_.addListen(_loc2_.slotId);
               }
            }
         }
         FightEventDispatcher.instance.addEventListener(PetFightEvent.CLICK_ITEM_HOLDER,this.onClickItemHolder);
         FightEventDispatcher.instance.addEventListener(PetFightEvent.CLICK_SKILL,this.onClickPet);
      }
      
      private function onClickItemHolder(param1:PetFightEvent) : void
      {
         if(param1.params.itemholder != this)
         {
            this.removeClickListener();
         }
      }
      
      private function onClickPet(param1:PetFightEvent) : void
      {
         this.removeClickListener();
         if(param1.params.haveHit)
         {
            this.removePetListen();
            this.useItem(FightData.instance.targetSlot);
         }
      }
      
      private function removeClickListener() : void
      {
         FightEventDispatcher.instance.removeEventListener(PetFightEvent.CLICK_ITEM_HOLDER,this.onClickItemHolder);
         FightEventDispatcher.instance.removeEventListener(PetFightEvent.CLICK_SKILL,this.onClickPet);
      }
      
      private function removePetListen() : void
      {
         var _loc2_:PlayerBattleInfo = null;
         var _loc3_:MCPetContainer = null;
         var _loc1_:FightPanel = FightController.instance.fightPanel;
         for each(_loc2_ in FightData.instance.playerInfo)
         {
            _loc3_ = _loc1_.petMCList[_loc2_.locaId];
            if(_loc1_.contains(_loc3_))
            {
               _loc3_.removeListen();
            }
         }
      }
   }
}

