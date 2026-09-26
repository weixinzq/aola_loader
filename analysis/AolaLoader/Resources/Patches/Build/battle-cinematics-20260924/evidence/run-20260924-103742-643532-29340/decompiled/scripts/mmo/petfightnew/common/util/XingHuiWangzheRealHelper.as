package mmo.petfightnew.common.util
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.geom.Point;
   import flash.system.ApplicationDomain;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class XingHuiWangzheRealHelper
   {
      
      private static const FLA:String = "xinghuipet/wangzhereal/status/wangzherealbird_";
      
      private static const KEY_STAND:String = "stand";
      
      private static const KEY_ATTACK:String = "attack";
      
      private static const KEY_ROUND_DOWN:String = "round_down";
      
      private static const KEY_ROUND_UP:String = "round_up";
      
      private static const CLS_STAND:String = "mmo.petfight.wangzhereal.Pet#Stand_";
      
      private static const CLS_ATTACK:String = "mmo.petfight.wangzhereal.Pet#Attack_";
      
      private static const CLS_ROUND_DOWN:String = "mmo.petfight.wangzhereal.Pet#RoundDown_";
      
      private static const CLS_ROUND_UP:String = "mmo.petfight.wangzhereal.Pet#RoundUp_";
      
      public function XingHuiWangzheRealHelper()
      {
         super();
      }
      
      public static function setStandStatus(param1:Sprite, param2:int, param3:Boolean, param4:int, param5:Number, param6:Number) : void
      {
         var key:String = null;
         var layer:Sprite = param1;
         var locaId:int = param2;
         var hasState:Boolean = param3;
         var raceId:int = param4;
         var x:Number = param5;
         var y:Number = param6;
         var face:int = getFace(locaId);
         key = KEY_STAND + "_" + locaId + "_" + face + "_bird";
         var hasView:Boolean = layer.getChildByName(key) != null;
         var pmService:IPMService = ServicePool.instance.getService(IPMService);
         var type:int = int(pmService.customData.pmDataMap.getPM(raceId).getXinghuiType());
         var isWangZhePet:Boolean = XinghuiPetType.WANGZHE_REAL == type;
         if(hasState && hasView)
         {
            layer.getChildByName(key).visible = isWangZhePet && raceId <= 10000;
            return;
         }
         if(raceId > 10000)
         {
            return;
         }
         if(!hasState && hasView)
         {
            layer.removeChild(layer.getChildByName(key));
            return;
         }
         if(!hasState)
         {
            return;
         }
         if(!isWangZhePet)
         {
            return;
         }
         ResScheduler.getRes(ResParams.createTempByDomain(FLA + raceId,function(param1:MovieClip, param2:ApplicationDomain):void
         {
            param1.x = x;
            param1.y = y;
            param1.name = key;
            layer.addChild(param1);
         },ResDomain.decorate(FightData.instance.applicationDomain),getReplacedStr(CLS_STAND,raceId.toString()) + face,ResPriority.LOW));
      }
      
      public static function setRoundDownState(param1:Sprite, param2:int, param3:String, param4:Number, param5:Number) : *
      {
         setRoundStatus(KEY_ROUND_DOWN,CLS_ROUND_DOWN,param1,param2,param3,param4,param5);
      }
      
      public static function setRoundUpState(param1:Sprite, param2:int, param3:String, param4:Number, param5:Number) : *
      {
         setRoundStatus(KEY_ROUND_UP,CLS_ROUND_UP,param1,param2,param3,param4,param5);
      }
      
      public static function setRoundStatus(param1:String, param2:String, param3:Sprite, param4:int, param5:String, param6:Number, param7:Number) : void
      {
         var _loc15_:* = undefined;
         var _loc16_:* = undefined;
         var _loc17_:DisplayObject = null;
         var _loc8_:int = getFace(param4);
         var _loc9_:* = param1 + "_" + param4 + "_" + _loc8_ + "_bird";
         var _loc10_:* = _loc9_ + "_";
         var _loc11_:Array = [];
         var _loc12_:int = 0;
         while(_loc12_ < param3.numChildren)
         {
            _loc17_ = param3.getChildAt(_loc12_);
            if(_loc17_.name.indexOf(param1) >= 0)
            {
               _loc11_.push(_loc17_.name.substring(_loc10_.length));
            }
            _loc12_++;
         }
         var _loc13_:Array = param5.length > 0 ? param5.split(",") : [];
         var _loc14_:int = 0;
         while(_loc14_ < _loc13_.length)
         {
            _loc13_[_loc14_] = (parseInt(_loc13_[_loc14_]) % 10000).toString();
            _loc14_++;
         }
         for each(_loc15_ in _loc11_)
         {
            if(_loc13_.indexOf(_loc15_) < 0)
            {
               removeChild(param3,_loc10_ + _loc15_);
            }
         }
         for each(_loc16_ in _loc13_)
         {
            if(_loc11_.indexOf(_loc16_) < 0)
            {
               addRoundStatus(param2,param3,param4,_loc10_ + _loc16_,_loc16_,param6,param7);
            }
         }
      }
      
      public static function playAttackMovie(param1:Sprite, param2:int, param3:String, param4:Function) : void
      {
         var pos:Point = null;
         var layer:Sprite = param1;
         var locaId:int = param2;
         var raceId:String = param3;
         var endFunc:Function = param4;
         var face:int = getFace(locaId);
         raceId = (parseInt(raceId) % 10000).toString();
         pos = PositionUtil.getDefaultPosition(locaId);
         ResScheduler.getRes(ResParams.createTempByDomain(FLA + raceId,function(param1:MovieClip, param2:ApplicationDomain):void
         {
            /*
             * Decompilation error
             * Code may be obfuscated
             * Tip: You can try enabling "Deobfuscate code" option in Settings
             * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
             */
            throw new flash.errors.IllegalOperationError("Not decompiled due to error");
         },ResDomain.decorate(FightData.instance.applicationDomain),getReplacedStr(CLS_ATTACK,raceId) + face));
      }
      
      private static function addRoundStatus(param1:*, param2:Sprite, param3:int, param4:String, param5:String, param6:Number, param7:Number) : void
      {
         var cls:* = param1;
         var layer:Sprite = param2;
         var locaId:int = param3;
         var key:String = param4;
         var raceId:String = param5;
         var x:Number = param6;
         var y:Number = param7;
         var face:int = getFace(locaId);
         ResScheduler.getRes(ResParams.createTempByDomain(FLA + raceId,function(param1:MovieClip, param2:ApplicationDomain):void
         {
            param1.x = x;
            param1.y = y;
            param1.name = key;
            layer.addChild(param1);
         },ResDomain.decorate(FightData.instance.applicationDomain),getReplacedStr(cls,raceId) + face));
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

