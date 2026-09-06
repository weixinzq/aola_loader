package mmo.petfightnew.common.panel.status
{
   import flash.display.Sprite;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.tips.TipsManager;
   import mmo.common.utils.tips.TipsType;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.material.hk.HKBuff;
   import mmo.interfaces.material.hk.HKHelp;
   import mmo.interfaces.option.IGameOptionService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.play.petfight.common.config.StampConfig;
   import mmo.play.petfight.commonbuff.CommonBuffHelper;
   import mmo.play.petfight.commonbuff.CommonBuffType;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1387")]
   public class NewStatusIconList extends Sprite implements IDispose
   {
      
      private static const ROW_STATUS_ICON_NUM:int = 8;
      
      private static const SPACE_X:int = 2;
      
      private static const SPACE_Y:int = 2;
      
      public static const TO_RIGHT:int = 0;
      
      public static const TO_LEFT:int = 1;
      
      private var _gameOptionSvr:IGameOptionService = ServicePool.instance.getService(IGameOptionService);
      
      private var _sortDirection:int = 0;
      
      private var _repeatX:int = 8;
      
      private var _iconList:Array = [];
      
      public function NewStatusIconList()
      {
         super();
         CommonEventDispatcher.instance.addEventListener("PetFightNew_HideSomeThing",this.isHideSomething);
      }
      
      public function set sortDirection(param1:int) : void
      {
         this._sortDirection = param1;
      }
      
      public function clear() : void
      {
         this.refresh([],null);
      }
      
      private function isHideSomething(param1:CommonEvent) : void
      {
         this.clear();
      }
      
      public function refresh(param1:Array, param2:PlayerBattleInfo) : void
      {
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:PetBriefInfo = null;
         var _loc8_:Vector.<HKBuff> = null;
         var _loc9_:int = 0;
         var _loc10_:StatusIcon = null;
         var _loc11_:HKBuff = null;
         var _loc12_:String = null;
         var _loc13_:int = 0;
         var _loc14_:int = 0;
         var _loc15_:StatusIcon = null;
         var _loc16_:int = 0;
         var _loc17_:StatusIcon = null;
         if(Boolean(this._gameOptionSvr.isHideFightSomething) && param1.length > 0)
         {
            return;
         }
         var _loc3_:int = 0;
         var _loc4_:Boolean = true;
         if(param1.length > 0)
         {
            param1 = this.sortStatus(param1);
            _loc5_ = 0;
            if(Boolean(param2) && FightData.instance.isChangZhuVisible)
            {
               _loc7_ = param2.myPets[0];
               _loc8_ = HKHelp.getActiveRareBuff(_loc7_.getHKIdArr(),_loc7_.getHKSlotLvArr());
               _loc9_ = 0;
               while(_loc9_ < _loc8_.length)
               {
                  if(this._iconList.length <= _loc5_)
                  {
                     this._iconList[_loc5_] = new StatusIcon();
                  }
                  _loc10_ = this._iconList[_loc5_];
                  _loc10_.x = this.getIconX(_loc5_);
                  _loc10_.y = this.getIconY(_loc5_);
                  _loc11_ = _loc8_[_loc9_];
                  _loc10_.startLoad(StatusIconHandler.StatusType_HK,1,0);
                  if(!this.contains(_loc10_))
                  {
                     this.addChild(_loc10_);
                  }
                  TipsManager.getInstance().replaceComplexTips(_loc10_,_loc11_.name,_loc11_.desArr[0],0,9,9,TipsType.NORMAL,true,180);
                  _loc5_++;
                  _loc9_++;
               }
            }
            _loc6_ = 0;
            while(_loc6_ < param1.length)
            {
               _loc12_ = param1[_loc6_];
               _loc13_ = StatusUtil.getFrame(_loc12_);
               _loc14_ = int(CommonBuffHelper.getResTurn(_loc12_));
               if(!((_loc14_ == 0 || _loc14_ > 100) && !FightData.instance.isChangZhuVisible))
               {
                  if(!(_loc13_ <= 0 || StatusUtil.SpecialStatusFrameArr.indexOf(_loc13_) != -1))
                  {
                     if(Boolean(CommonBuffHelper.getIsCommonBuff(_loc12_)) && _loc4_)
                     {
                        _loc16_ = int(CommonBuffHelper.getTypeById(parseInt(_loc12_.split("_")[1])));
                        if(_loc16_ == CommonBuffType.DeBuff)
                        {
                           _loc4_ = false;
                           if(_loc5_ < ROW_STATUS_ICON_NUM && _loc5_ > 0)
                           {
                              _loc3_ = ROW_STATUS_ICON_NUM - _loc5_;
                              _loc5_ = ROW_STATUS_ICON_NUM;
                           }
                        }
                     }
                     if(this._iconList.length <= _loc5_ - _loc3_)
                     {
                        this._iconList[_loc5_ - _loc3_] = new StatusIcon();
                     }
                     _loc15_ = this._iconList[_loc5_ - _loc3_];
                     _loc15_.x = this.getIconX(_loc5_);
                     _loc15_.y = this.getIconY(_loc5_);
                     if(StatusUtil.isGQSkillWindWord(_loc12_))
                     {
                        _loc15_.startLoad(StatusIconHandler.StatusType_CommonBuff,_loc13_,CommonBuffHelper.getResTurn(_loc12_));
                     }
                     else if(_loc12_.split("_").length < 5)
                     {
                        _loc15_.startLoad(StatusIconHandler.StatusType_Common,_loc13_,0);
                     }
                     else
                     {
                        _loc15_.startLoad(StatusIconHandler.StatusType_Common,_loc13_,Number(_loc12_.split("_")[4]));
                     }
                     if(!this.contains(_loc15_))
                     {
                        this.addChild(_loc15_);
                     }
                     TipsManager.getInstance().replaceComplexTips(_loc15_,StatusUtil.getTips(_loc12_),StatusUtil.getDetailTips(_loc12_));
                     _loc5_++;
                  }
               }
               _loc6_++;
            }
         }
         _loc6_ = _loc5_ - _loc3_;
         while(_loc6_ < this._iconList.length)
         {
            _loc17_ = this._iconList[_loc6_];
            if(_loc17_)
            {
               TipsManager.getInstance().removeTips(_loc17_);
               _loc17_.clearIcon();
            }
            _loc6_++;
         }
      }
      
      private function sortStatus(param1:Array) : Array
      {
         var _loc15_:String = null;
         var _loc16_:int = 0;
         var _loc17_:int = 0;
         var _loc2_:Array = [];
         var _loc3_:Array = [];
         var _loc4_:Array = [];
         var _loc5_:Array = [];
         var _loc6_:Array = [];
         var _loc7_:Array = [];
         var _loc8_:Array = [];
         var _loc9_:Array = [];
         var _loc10_:Array = [];
         var _loc11_:Array = [];
         var _loc12_:Array = [];
         var _loc13_:Array = [];
         var _loc14_:int = 0;
         while(_loc14_ < param1.length)
         {
            _loc15_ = param1[_loc14_];
            if(StampConfig.checkIsStampStatus(_loc15_))
            {
               _loc2_.push(_loc15_);
            }
            else if(StatusUtil.isGQTujian(_loc15_))
            {
               _loc3_.push(_loc15_);
            }
            else if(_loc15_.indexOf("suit_") != -1)
            {
               _loc16_ = parseInt(_loc15_.split("_")[2]);
               if(_loc16_ == 2)
               {
                  _loc4_.push(_loc15_);
               }
               else if(_loc16_ == 3)
               {
                  _loc5_.push(_loc15_);
               }
               else
               {
                  _loc6_.push(_loc15_);
               }
            }
            else if(_loc15_ == "lingzhu" || _loc15_ == "shouhuzhe")
            {
               _loc7_.push(_loc15_);
            }
            else if(_loc15_.indexOf("slt_") != -1 || _loc15_.indexOf("sltex_") != -1)
            {
               _loc8_.push(_loc15_);
            }
            else if(StatusUtil.isShenBenStatus(_loc15_))
            {
               _loc9_.push(_loc15_);
            }
            else if(_loc15_.indexOf("gqboss") != -1)
            {
               _loc10_.push(_loc15_);
            }
            else if(CommonBuffHelper.getIsCommonBuff(_loc15_))
            {
               _loc17_ = int(CommonBuffHelper.getTypeById(parseInt(_loc15_.split("_")[1])));
               if(_loc17_ != CommonBuffType.NuUrl)
               {
                  if(_loc17_ == CommonBuffType.DeBuff)
                  {
                     _loc12_.push(_loc15_);
                  }
                  else if(_loc17_ == CommonBuffType.IncreaseBuff)
                  {
                     _loc11_.unshift(_loc15_);
                  }
                  else
                  {
                     _loc11_.push(_loc15_);
                  }
               }
            }
            else
            {
               _loc13_.push(_loc15_);
            }
            _loc14_++;
         }
         _loc11_.sort(this.sortCommonBuff);
         _loc12_.sort(this.sortCommonBuff);
         return _loc2_.concat(_loc3_).concat(_loc4_).concat(_loc5_).concat(_loc6_).concat(_loc7_).concat(_loc8_).concat(_loc9_).concat(_loc10_).concat(_loc11_).concat(_loc12_).concat(_loc13_);
      }
      
      private function sortCommonBuff(param1:String, param2:String) : int
      {
         return CommonBuffHelper.getResTurn(param2) - CommonBuffHelper.getResTurn(param1);
      }
      
      private function getIconX(param1:int) : Number
      {
         var _loc2_:int = 0;
         if(this._repeatX > 0)
         {
            _loc2_ = Math.floor(param1 % this._repeatX);
         }
         else
         {
            _loc2_ = param1;
         }
         if(this._sortDirection == TO_RIGHT)
         {
            return _loc2_ * (StatusIcon.ICON_WIDTH + SPACE_X);
         }
         return -((_loc2_ + 1) * (StatusIcon.ICON_WIDTH + SPACE_X));
      }
      
      private function getIconY(param1:int) : Number
      {
         var _loc2_:int = 0;
         if(this._repeatX > 0)
         {
            _loc2_ = Math.floor(param1 / this._repeatX);
         }
         else
         {
            _loc2_ = 0;
         }
         return _loc2_ * (StatusIcon.ICON_HEIGHT + SPACE_Y);
      }
      
      public function get repeatX() : int
      {
         return this._repeatX;
      }
      
      public function set repeatX(param1:int) : void
      {
         this._repeatX = param1;
      }
      
      public function dispose() : void
      {
         var _loc1_:StatusIcon = null;
         for each(_loc1_ in this._iconList)
         {
            _loc1_.dispose();
         }
         this._iconList = [];
         CommonEventDispatcher.instance.removeEventListener("PetFightNew_HideSomeThing",this.isHideSomething);
      }
   }
}

