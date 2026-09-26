package mmo.petfightnew.common.util
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.pet.data.PetAssetsMap;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class GQBuxiuLvtuEffecthelper
   {
      
      private static const FLA:String = "gqpet/buxiulvtu/effect/buxiulvtueffect_";
      
      private static const KEY_STAND:String = "gq_bxlt_stand";
      
      private static const KEY_ATTACK:String = "gq_bxlt_attack";
      
      private static const CLS_STAND:String = "mmo.gqpet.buxiulvtu.effect.Pet#Stand_";
      
      private static const CLS_ATTACK:String = "mmo.gqpet.buxiulvtu.effect.Pet#Attack_";
      
      private static const LayerPetUpLevels:Array = [2,3,4,5];
      
      public function GQBuxiuLvtuEffecthelper()
      {
         super();
      }
      
      public static function setStandStatus(param1:Sprite, param2:Sprite, param3:int, param4:PetBriefInfo, param5:Number, param6:Number) : void
      {
         var _loc18_:MovieClip = null;
         var _loc19_:String = null;
         var _loc7_:int = getFace(param3);
         var _loc8_:int = int(PetAssetsMap.getPetFlaId(param4.raceId));
         var _loc9_:String = KEY_STAND + "_" + param3 + "_" + _loc7_;
         var _loc10_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc11_:int = int(_loc10_.customData.pmDataMap.getPM(param4.raceId).getGQType());
         var _loc12_:int = StatusUtil.getBuxiuJixingLevel(param4);
         var _loc13_:int = int(param4.curHp);
         var _loc14_:Boolean = Boolean(GQPetType.isBuxiuLvtu(_loc11_)) && _loc12_ > 0 && _loc13_ > 0;
         var _loc15_:int = param1.numChildren - 1;
         while(_loc15_ >= 0)
         {
            _loc18_ = param1.getChildAt(_loc15_) as MovieClip;
            if(_loc18_)
            {
               if(_loc18_.name.indexOf(_loc9_) != -1 && (parseInt(_loc18_.name.split("#")[1]) != _loc8_ || parseInt(_loc18_.name.split("#")[2]) > _loc12_ || _loc13_ <= 0))
               {
                  DisplayUtil.stopAndRemove(_loc18_);
               }
            }
            _loc15_--;
         }
         var _loc16_:int = param2.numChildren - 1;
         while(_loc16_ >= 0)
         {
            _loc18_ = param2.getChildAt(_loc16_) as MovieClip;
            if(_loc18_)
            {
               if(_loc18_.name.indexOf(_loc9_) != -1 && (parseInt(_loc18_.name.split("#")[1]) != _loc8_ || parseInt(_loc18_.name.split("#")[2]) > _loc12_ || _loc13_ <= 0))
               {
                  DisplayUtil.stopAndRemove(_loc18_);
               }
            }
            _loc16_--;
         }
         if(!_loc14_)
         {
            return;
         }
         var _loc17_:int = 2;
         while(_loc17_ <= _loc12_)
         {
            _loc19_ = _loc9_ + "#" + _loc8_ + "#" + _loc17_;
            if(LayerPetUpLevels.indexOf(_loc17_) != -1)
            {
               if(param1.getChildByName(_loc19_) == null)
               {
                  loadAndAddStandMc(_loc8_,param1,param4,_loc7_,_loc19_,_loc17_,param5,param6);
               }
            }
            else if(param2.getChildByName(_loc19_) == null)
            {
               loadAndAddStandMc(_loc8_,param2,param4,_loc7_,_loc19_,_loc17_,param5,param6);
            }
            _loc17_++;
         }
      }
      
      private static function loadAndAddStandMc(param1:int, param2:Sprite, param3:PetBriefInfo, param4:int, param5:String, param6:int, param7:Number, param8:Number) : void
      {
         var raceId:int = param1;
         var layer:Sprite = param2;
         var thePet:PetBriefInfo = param3;
         var face:int = param4;
         var key:String = param5;
         var level:int = param6;
         var x:Number = param7;
         var y:Number = param8;
         ResScheduler.getRes(ResParams.createTempByDomain(FLA + raceId,function(param1:MovieClip, param2:ApplicationDomain):void
         {
            param1.x = x;
            param1.y = y;
            param1.name = key;
            layer.addChild(param1);
         },ResDomain.decorate(FightData.instance.applicationDomain),getReplacedStr(CLS_STAND,raceId.toString()) + face + "_" + level,ResPriority.LOW));
      }
      
      public static function playAttackMovie(param1:Sprite, param2:Sprite, param3:int, param4:PetBriefInfo, param5:Function) : void
      {
         var _loc6_:int = getFace(param3);
         var _loc7_:int = int(PetAssetsMap.getPetFlaId(param4.raceId));
         var _loc8_:String = KEY_ATTACK + "_" + param3 + "_" + _loc6_;
         var _loc9_:int = StatusUtil.getBuxiuJixingLevel(param4);
         var _loc10_:String = _loc8_ + "#" + _loc7_ + "#" + _loc9_;
         var _loc11_:int = 2;
         while(_loc11_ <= _loc9_)
         {
            if(LayerPetUpLevels.indexOf(_loc11_) != -1)
            {
               loadAndAddAttckMc(_loc7_,param1,param4,_loc6_,_loc10_,_loc11_,param3);
            }
            else
            {
               loadAndAddAttckMc(_loc7_,param2,param4,_loc6_,_loc10_,_loc11_,param3);
            }
            _loc11_++;
         }
      }
      
      private static function loadAndAddAttckMc(param1:int, param2:Sprite, param3:PetBriefInfo, param4:int, param5:String, param6:int, param7:int) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private static function removeChild(param1:Sprite, param2:String) : *
      {
         if(param1.getChildByName(param2) != null)
         {
            param1.removeChild(param1.getChildByName(param2));
         }
      }
      
      private static function getFace(param1:int) : int
      {
         return FightData.instance.isMySide(param1) ? 2 : 1;
      }
      
      private static function getReplacedStr(param1:String, param2:String) : String
      {
         return param1.replace("#",param2);
      }
   }
}

