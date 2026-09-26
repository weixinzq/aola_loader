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
   
   public class SkillBackgroundBuff1453Handler implements IDispose
   {
      
      private static const BuffId:int = 1453;
      
      private static const Url:String = "skillbackground/skillbackground_buff1453_";
      
      private static const AppearCls:String = "mmo.skillbackground.Buff1453Appear_";
      
      private static const KuangCls:String = "mmo.skillbackground.Buff1453_";
      
      private static const DisappearCls:String = "mmo.skillbackground.Buff1453Disappear_";
      
      private var _isHasEffect:Array = [false,false];
      
      private var _commonBuffPetDownLayer:DisplayObjectContainer;
      
      public function SkillBackgroundBuff1453Handler(param1:DisplayObjectContainer)
      {
         super();
         this._commonBuffPetDownLayer = param1;
         this._commonBuffPetDownLayer.mouseChildren = this._commonBuffPetDownLayer.mouseEnabled = false;
      }
      
      public function refreshBg() : void
      {
         var _loc1_:Array = this.getBuffState();
         var _loc2_:Boolean = !this._isHasEffect[0] && Boolean(_loc1_[0]);
         var _loc3_:Boolean = !this._isHasEffect[1] && Boolean(_loc1_[1]);
         var _loc4_:Boolean = Boolean(this._isHasEffect[0]) && !_loc1_[0];
         var _loc5_:Boolean = Boolean(this._isHasEffect[1]) && !_loc1_[1];
         this.addEffect(_loc2_,_loc3_);
         this.removeEffect(_loc4_,_loc5_);
      }
      
      public function dispose() : void
      {
         DisplayUtil.stopAndRemove(this._commonBuffPetDownLayer);
      }
      
      private function addEffect(param1:Boolean, param2:Boolean) : void
      {
         if(!param1 && !param2)
         {
            return;
         }
         if(param1)
         {
            this._isHasEffect[0] = true;
            this.addBuffEffect(0);
         }
         if(param2)
         {
            this._isHasEffect[1] = true;
            this.addBuffEffect(1);
         }
      }
      
      private function removeEffect(param1:Boolean, param2:Boolean) : void
      {
         if(!param1 && !param2)
         {
            return;
         }
         if(param1)
         {
            this._isHasEffect[0] = false;
            this.removeBuffEffect(0);
         }
         if(param2)
         {
            this._isHasEffect[1] = false;
            this.removeBuffEffect(1);
         }
      }
      
      private function getBuffState() : Array
      {
         var _loc2_:PlayerBattleInfo = null;
         var _loc3_:PetBriefInfo = null;
         var _loc1_:Array = [false,false];
         for each(_loc2_ in FightData.instance.playerInfo)
         {
            _loc3_ = _loc2_.myPets[0];
            if(FightData.instance.isMySide(_loc2_.locaId))
            {
               if(this.isHasBuff(_loc3_))
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
      
      private function isHasBuff(param1:PetBriefInfo) : Boolean
      {
         var _loc4_:String = null;
         var _loc2_:Array = StatusUtil.parseStatusStr(param1.status);
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc4_ = _loc2_[_loc3_];
            if(CommonBuffHelper.getIsCommonBuff(_loc4_))
            {
               if(BuffId == parseInt(_loc4_.split("_")[1]))
               {
                  return true;
               }
            }
            _loc3_++;
         }
         return false;
      }
      
      private function addBuffEffect(param1:int) : void
      {
         var index:int = param1;
         try
         {
            ResScheduler.getResource(Url + index,function(param1:MovieClip):void
            {
               var mc:MovieClip = param1;
               if(!_isHasEffect[index])
               {
                  return;
               }
               mc.name = "Buff1453Appear_" + index;
               mc.addFrameScript(mc.totalFrames - 1,function():void
               {
                  DisplayUtil.stopAndRemove(mc);
                  var _loc1_:String = KuangCls + index;
                  var _loc2_:Class = FightData.instance.applicationDomain.getDefinition(_loc1_) as Class;
                  var _loc3_:DisplayObject = new _loc2_() as DisplayObject;
                  _loc3_.name = "Buff1453_" + index;
                  _commonBuffPetDownLayer.addChild(_loc3_);
               });
               mc.gotoAndPlay(1);
               _commonBuffPetDownLayer.addChild(mc);
            },AppearCls + index,function():void
            {
            },null,ResPriority.NORMAL,false,FightData.instance.applicationDomain);
         }
         catch(e:*)
         {
         }
      }
      
      private function removeBuffEffect(param1:int) : void
      {
         var index:int = param1;
         if(!this._commonBuffPetDownLayer || !this._commonBuffPetDownLayer.parent)
         {
            return;
         }
         try
         {
            ResScheduler.getResource(Url + index,function(param1:MovieClip):void
            {
               var mc:MovieClip = param1;
               var kuangmc:MovieClip = _commonBuffPetDownLayer.getChildByName("Buff1453_" + index) as MovieClip;
               DisplayUtil.stopAndRemove(kuangmc);
               mc.name = "Buff1453Appear_" + index;
               mc.addFrameScript(mc.totalFrames - 1,function():void
               {
                  DisplayUtil.stopAndRemove(mc);
               });
               mc.gotoAndPlay(1);
               _commonBuffPetDownLayer.addChild(mc);
            },DisappearCls + index,function():void
            {
            },null,ResPriority.NORMAL,false,FightData.instance.applicationDomain);
         }
         catch(e:*)
         {
         }
      }
   }
}

