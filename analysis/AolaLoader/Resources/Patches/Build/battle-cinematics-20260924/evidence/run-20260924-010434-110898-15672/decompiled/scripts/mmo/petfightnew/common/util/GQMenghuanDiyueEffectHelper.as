package mmo.petfightnew.common.util
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.geom.Point;
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
   
   public class GQMenghuanDiyueEffectHelper
   {
      
      private static const FLA:String = "gqpet/menghuandiyue/effect/menghuandiyueeffect_";
      
      private static const KEY_STAND:String = "gq_mhdy_stand";
      
      private static const KEY_ATTACK:String = "gq_mhdy_attack";
      
      private static const CLS_STAND:String = "mmo.gqpet.menghuandiyue.effect.Pet#Stand_";
      
      private static const CLS_ATTACK:String = "mmo.gqpet.menghuandiyue.effect.Pet#Attack_";
      
      public function GQMenghuanDiyueEffectHelper()
      {
         super();
      }
      
      public static function setStandStatus(param1:Sprite, param2:int, param3:PetBriefInfo, param4:Number, param5:Number) : void
      {
         var hasView:Boolean;
         var pmService:IPMService;
         var gqPetType:int;
         var isMenghuanDiyuePet:Boolean;
         var key:String = null;
         var mc:MovieClip = null;
         var layer:Sprite = param1;
         var locaId:int = param2;
         var thePet:PetBriefInfo = param3;
         var x:Number = param4;
         var y:Number = param5;
         var face:int = getFace(locaId);
         var raceId:int = int(PetAssetsMap.getPetFlaId(thePet.raceId));
         key = KEY_STAND + "_" + locaId + "_" + face + "#" + raceId + "#bird";
         var i:int = layer.numChildren - 1;
         while(i >= 0)
         {
            mc = layer.getChildAt(i) as MovieClip;
            if(mc)
            {
               if(mc.name.indexOf(KEY_STAND + "_" + locaId + "_" + face) != -1 && parseInt(mc.name.split("#")[1]) != raceId)
               {
                  DisplayUtil.stopAndRemove(mc);
               }
            }
            i--;
         }
         hasView = layer.getChildByName(key) != null;
         pmService = ServicePool.instance.getService(IPMService);
         gqPetType = int(pmService.customData.pmDataMap.getPM(thePet.raceId).getGQType());
         isMenghuanDiyuePet = Boolean(GQPetType.isMenghuanDiyue(gqPetType));
         if(hasView)
         {
            layer.getChildByName(key).visible = isMenghuanDiyuePet && thePet.curHp > 0;
            return;
         }
         if(!isMenghuanDiyuePet)
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
      
      public static function playAttackMovie(param1:Sprite, param2:int, param3:int, param4:Function) : void
      {
         var effectMc:MovieClip = null;
         var pos:Point = null;
         var layer:Sprite = param1;
         var locaId:int = param2;
         var raceId:int = param3;
         var endFunc:Function = param4;
         var face:int = getFace(locaId);
         raceId = int(PetAssetsMap.getPetFlaId(raceId));
         var key:String = KEY_STAND + "_" + locaId + "_" + face + "#" + raceId + "#bird";
         effectMc = layer.getChildByName(key) as MovieClip;
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
         },ResDomain.decorate(FightData.instance.applicationDomain),getReplacedStr(CLS_ATTACK,raceId.toString()) + face));
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

