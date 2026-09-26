package mmo.petfightnew.common.util
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.gq.GQPetType;
   import mmo.interfaces.pet.data.PetAssetsMap;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class GQWanyuZhichaoEffectHelper
   {
      
      private static const FLA:String = "gqpet/wanyuzhichao/effect/wanyuzhichaoeffect_";
      
      private static const KEY_STAND:String = "gq_wyzc_stand";
      
      private static const KEY_ATTACK:String = "gq_wyzc_attack";
      
      private static const CLS_STAND:String = "mmo.gqpet.wanyuzhichao.effect.Pet#Stand_";
      
      private static const CLS_ATTACK:String = "mmo.gqpet.wanyuzhichao.effect.Pet#Attack_";
      
      public function GQWanyuZhichaoEffectHelper()
      {
         super();
      }
      
      public static function setStandStatus(param1:Sprite, param2:int, param3:PetBriefInfo, param4:Number, param5:Number) : void
      {
         var hasView:Boolean;
         var pmService:IPMService;
         var gqPetType:int;
         var isWanyuZhichaoPetAndHasEffect:Boolean;
         var key:String = null;
         var mc:MovieClip = null;
         var layer:Sprite = param1;
         var locaId:int = param2;
         var thePet:PetBriefInfo = param3;
         var x:Number = param4;
         var y:Number = param5;
         var pmSvr:IPMService = ServicePool.instance.getService(IPMService);
         var face:int = getFace(locaId);
         var raceId:int = int(PetAssetsMap.getPetFlaId(pmSvr.getOperationPM(thePet.raceId).getMaxCommonEvlution().raceId));
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
         isWanyuZhichaoPetAndHasEffect = Boolean(GQPetType.isWanYuZhiChao(gqPetType)) && StatusUtil.getIsWanyuZhichaoHasXuying(thePet);
         if(hasView)
         {
            layer.getChildByName(key).visible = isWanyuZhichaoPetAndHasEffect && thePet.curHp > 0;
            return;
         }
         if(!isWanyuZhichaoPetAndHasEffect)
         {
            return;
         }
         ResScheduler.getRes(ResParams.createTempByDomain(FLA + raceId,function(param1:MovieClip, param2:ApplicationDomain):void
         {
            param1.mouseChildren = param1.mouseEnabled = false;
            param1.name = key;
            layer.addChild(param1);
         },ResDomain.decorate(FightData.instance.applicationDomain),getReplacedStr(CLS_STAND,raceId.toString()) + face,ResPriority.LOW));
      }
      
      public static function playAttackMovie(param1:Sprite, param2:int, param3:int, param4:Function) : void
      {
         var key:String;
         var player:PlayerBattleInfo = null;
         var effectMc:MovieClip = null;
         var layer:Sprite = param1;
         var locaId:int = param2;
         var raceId:int = param3;
         var endFunc:Function = param4;
         var pmService:IPMService = ServicePool.instance.getService(IPMService);
         var face:int = getFace(locaId);
         var players:Array = FightData.instance.isMySide(locaId) ? FightData.instance.teammates : FightData.instance.opponents;
         var thePet:PetBriefInfo = null;
         for each(player in players)
         {
            if(Boolean(GQPetType.isWanYuZhiChao(pmService.customData.pmDataMap.getPM(player.myPets[0].raceId).getGQType())) && StatusUtil.getIsWanyuZhichaoHasXuying(player.myPets[0]))
            {
               thePet = player.myPets[0];
               locaId = int(player.locaId);
               raceId = int(PetAssetsMap.getPetFlaId(pmService.getOperationPM(thePet.raceId).getMaxCommonEvlution().raceId));
               break;
            }
         }
         if(thePet == null || thePet.curHp <= 0)
         {
            endFunc && endFunc.apply();
            return;
         }
         key = KEY_STAND + "_" + locaId + "_" + face + "#" + raceId + "#bird";
         effectMc = layer.getChildByName(key) as MovieClip;
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

