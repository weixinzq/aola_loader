package mmo.petfightnew.common.panel
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightItemData;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.panel.item.NewItemHolder;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1650")]
   public class CatchPanel extends UIPanelBase implements IDispose
   {
      
      public var btnLeft:SimpleButton;
      
      public var btnRight:SimpleButton;
      
      public var hd0:TextField;
      
      public var hd1:TextField;
      
      public var hd2:TextField;
      
      public var hd3:TextField;
      
      public var hd4:TextField;
      
      public var hd5:TextField;
      
      public var mcCatchTips:MovieClip;
      
      public var s0:MovieClip;
      
      public var s1:MovieClip;
      
      public var s2:MovieClip;
      
      public var s3:MovieClip;
      
      public var s4:MovieClip;
      
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
      
      private var _petSkillMesService:IPetSkillMesService;
      
      private var _mcCatchTips:MovieClip;
      
      public function CatchPanel()
      {
         super();
         this._petSkillMesService = ServicePool.instance.getService(IPetSkillMesService);
         this._myFightItems = FightItemData.instance.myCatchItems;
         this._totalPage = Math.max(1,Math.ceil(this._myFightItems.length / this.PAGE_ITEM_NUM));
         this._mcCatchTips = this.getChild("mcCatchTips");
         this._txtPage = this.getChild("txtPage");
         this._txtPage.mouseEnabled = false;
         this._btnLeft = this.getChild("btnLeft");
         this._btnLeft.addEventListener(MouseEvent.CLICK,this.onLeft);
         this._btnRight = this.getChild("btnRight");
         this._btnRight.addEventListener(MouseEvent.CLICK,this.onRight);
         this.update();
         this.updateCatchInfo();
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
                  this._itemHolderList[_loc3_] = _loc2_ = new CatchItemHolder();
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
      
      private function updateCatchInfo() : void
      {
         this.setCatchTips();
         this.updateStarNums();
      }
      
      private function setCatchTips() : void
      {
         var _loc3_:int = 0;
         var _loc1_:PlayerBattleInfo = FightData.instance.playerInfo[FightData.instance.vsSlot] as PlayerBattleInfo;
         var _loc2_:PetBriefInfo = _loc1_.myPets[0] as PetBriefInfo;
         if(_loc2_.curHp >= 0.6 * _loc2_.maxHp)
         {
            _loc3_ = 1;
         }
         else if(_loc2_.curHp >= 0.4 * _loc2_.maxHp)
         {
            _loc3_ = 2;
         }
         else if(_loc2_.curHp >= 0.2 * _loc2_.maxHp)
         {
            _loc3_ = 3;
         }
         else
         {
            _loc3_ = 4;
         }
         this._mcCatchTips.gotoAndStop(_loc3_);
      }
      
      private function updateStarNums() : void
      {
         var _loc5_:int = 0;
         var _loc1_:PlayerBattleInfo = FightData.instance.playerInfo[FightData.instance.vsSlot] as PlayerBattleInfo;
         var _loc2_:PetBriefInfo = _loc1_.myPets[0] as PetBriefInfo;
         var _loc3_:Object = this._petSkillMesService.getPetMes(_loc2_.raceId);
         var _loc4_:int = this.calCatchRate(_loc3_.catchRate1,_loc3_.catchRate2);
         if(_loc4_ >= 14)
         {
            _loc5_ = 1;
         }
         else if(_loc4_ >= 7)
         {
            _loc5_ = 2;
         }
         else if(_loc4_ >= 5)
         {
            _loc5_ = 3;
         }
         else
         {
            _loc5_ = 4;
         }
         this.setStars(_loc5_ * 2);
      }
      
      private function setStars(param1:int) : void
      {
         var _loc5_:MovieClip = null;
         var _loc2_:int = Math.ceil(param1 / 2) - 1;
         var _loc3_:int = param1 % 2;
         var _loc4_:int = 0;
         while(_loc4_ < 5)
         {
            _loc5_ = this.getChildByName("s" + _loc4_.toString()) as MovieClip;
            if(_loc4_ > _loc2_)
            {
               _loc5_.gotoAndStop(3);
            }
            else if(_loc4_ < _loc2_ || _loc3_ == 0)
            {
               _loc5_.gotoAndStop(1);
            }
            else
            {
               _loc5_.gotoAndStop(2);
            }
            _loc4_++;
         }
      }
      
      private function calCatchRate(param1:int, param2:int) : int
      {
         var _loc3_:Number = 0.013 * param1 * param1 - 2.18 * param1 + 85;
         var _loc4_:Number = param1 / 15;
         var _loc5_:Number = param1 > 50 ? param1 - 50 : 0;
         var _loc6_:int = int(0.1 * _loc5_ * param2);
         var _loc7_:int = int(0.3 * (_loc3_ + _loc4_ + _loc6_));
         if(_loc7_ > 70)
         {
            _loc7_ = 70;
         }
         else if(_loc7_ < 0)
         {
            _loc7_ = 0;
         }
         return _loc7_;
      }
   }
}

