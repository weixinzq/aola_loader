package mmo.petfightnew.common.handler.custombg
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.play.petfight.commonbuff.CommonBuffHelper;
   
   public class HunDunKongJianEffectHandle implements IDispose
   {
      
      private var _isHasHunKongJianEffect:Array = [false,false];
      
      private var _hunKongJianId:int = 1393;
      
      private const Url:String = "skillbackground/hundunkongjianeffect_";
      
      private const AppearCls:String = "gqpet.hundunkongjianAppearEffect_";
      
      private const KuangCls:String = "gqpet.hundunkongjianKuangEffect_";
      
      private const DisappearCls:String = "gqpet.hundunkongjianDisappear_";
      
      private var _layerHunDunPetDown:DisplayObjectContainer;
      
      public function HunDunKongJianEffectHandle(param1:DisplayObjectContainer)
      {
         super();
         this._layerHunDunPetDown = param1;
         this._layerHunDunPetDown.mouseChildren = this._layerHunDunPetDown.mouseEnabled = false;
      }
      
      public function dispose() : void
      {
         DisplayUtil.stopAndRemove(this._layerHunDunPetDown);
      }
      
      public function refresHunDunJueDouKongJianBg() : void
      {
         var _loc1_:Array = this.getHunDunKongJianBuffState();
         var _loc2_:Boolean = !this._isHasHunKongJianEffect[0] && Boolean(_loc1_[0]);
         var _loc3_:Boolean = !this._isHasHunKongJianEffect[1] && Boolean(_loc1_[1]);
         var _loc4_:Boolean = Boolean(this._isHasHunKongJianEffect[0]) && !_loc1_[0];
         var _loc5_:Boolean = Boolean(this._isHasHunKongJianEffect[1]) && !_loc1_[1];
         this.addHunDunJueDouKongJianEffect(_loc2_,_loc3_);
         this.removeHunDunJueDouKongJianEffect(_loc4_,_loc5_);
      }
      
      private function addHunDunJueDouKongJianEffect(param1:Boolean, param2:Boolean) : void
      {
         if(!param1 && !param2)
         {
            return;
         }
         if(param1)
         {
            this._isHasHunKongJianEffect[0] = true;
            this.addHunDunKongJianEffect(0);
         }
         if(param2)
         {
            this._isHasHunKongJianEffect[1] = true;
            this.addHunDunKongJianEffect(1);
         }
      }
      
      private function removeHunDunJueDouKongJianEffect(param1:Boolean, param2:Boolean) : void
      {
         if(!param1 && !param2)
         {
            return;
         }
         if(param1)
         {
            this._isHasHunKongJianEffect[0] = false;
            this.removeHunDunKongJianEffect(0);
         }
         if(param2)
         {
            this._isHasHunKongJianEffect[1] = false;
            this.removeHunDunKongJianEffect(1);
         }
      }
      
      private function getHunDunKongJianBuffState() : Array
      {
         var _loc2_:PlayerBattleInfo = null;
         var _loc3_:PetBriefInfo = null;
         var _loc1_:Array = [false,false];
         for each(_loc2_ in FightData.instance.playerInfo)
         {
            _loc3_ = _loc2_.myPets[0];
            if(FightData.instance.isMySide(_loc2_.locaId))
            {
               if(this.isHasHunDunJueDouKongJianBuff(_loc3_))
               {
                  if(_loc2_.locaId == 0 || _loc2_.locaId == 2)
                  {
                     _loc1_[0] = true;
                  }
                  else if(_loc2_.locaId == 1 || _loc2_.locaId == 3)
                  {
                     _loc1_[1] = true;
                  }
               }
            }
         }
         return _loc1_;
      }
      
      private function isHasHunDunJueDouKongJianBuff(param1:PetBriefInfo) : Boolean
      {
         var _loc4_:String = null;
         var _loc2_:Array = StatusUtil.parseStatusStr(param1.status);
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc4_ = _loc2_[_loc3_];
            if(CommonBuffHelper.getIsCommonBuff(_loc4_))
            {
               if(this._hunKongJianId == parseInt(_loc4_.split("_")[1]))
               {
                  return true;
               }
            }
            _loc3_++;
         }
         return false;
      }
      
      private function addHunDunKongJianEffect(param1:int) : void
      {
         var index:int = param1;
         try
         {
            ResScheduler.getResource(this.Url + index,function(param1:MovieClip):void
            {
               var mc:MovieClip = param1;
               if(!_isHasHunKongJianEffect[index])
               {
                  return;
               }
               mc.name = "hundunkongjianAppearEffect_" + index;
               mc.addFrameScript(mc.totalFrames - 1,function():void
               {
                  _layerHunDunPetDown.removeChild(mc);
                  DisplayUtil.stopAndRemove(mc);
                  var _loc1_:String = KuangCls + index;
                  var _loc2_:Class = FightData.instance.applicationDomain.getDefinition(_loc1_) as Class;
                  var _loc3_:DisplayObject = new _loc2_() as DisplayObject;
                  _loc3_.name = "hundunkongjianKuangEffect_" + index;
                  _layerHunDunPetDown.addChild(_loc3_);
               });
               mc.gotoAndPlay(1);
               _layerHunDunPetDown.addChild(mc);
            },this.AppearCls + index,function():void
            {
            },null,ResPriority.NORMAL,false,FightData.instance.applicationDomain);
         }
         catch(e:*)
         {
         }
      }
      
      private function removeHunDunKongJianEffect(param1:int) : void
      {
         var index:int = param1;
         if(!this._layerHunDunPetDown)
         {
            return;
         }
         try
         {
            ResScheduler.getResource(this.Url + index,function(param1:MovieClip):void
            {
               var mc:MovieClip = param1;
               var kuangmc:MovieClip = _layerHunDunPetDown.getChildByName("hundunkongjianKuangEffect_" + index) as MovieClip;
               if(kuangmc)
               {
                  _layerHunDunPetDown.removeChild(kuangmc);
               }
               mc.name = "hundunkongjianDisappear_" + index;
               mc.addFrameScript(mc.totalFrames - 1,function():void
               {
                  _layerHunDunPetDown.removeChild(mc);
                  DisplayUtil.stopAndRemove(mc);
               });
               mc.gotoAndPlay(1);
               _layerHunDunPetDown.addChild(mc);
            },this.DisappearCls + index,function():void
            {
            },null,ResPriority.NORMAL,false,FightData.instance.applicationDomain);
         }
         catch(e:*)
         {
         }
      }
   }
}

