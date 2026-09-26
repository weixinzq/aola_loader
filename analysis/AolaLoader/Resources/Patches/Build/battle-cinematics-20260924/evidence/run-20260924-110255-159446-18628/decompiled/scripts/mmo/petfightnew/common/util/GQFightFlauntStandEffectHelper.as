package mmo.petfightnew.common.util
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.interfaces.material.fightflauntresource.IFightFlauntResourceService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class GQFightFlauntStandEffectHelper
   {
      
      private static const KEY_STAND:String = "fightflauntstand";
      
      private static var _ffrSvr:IFightFlauntResourceService = ServicePool.instance.getService(IFightFlauntResourceService);
      
      public function GQFightFlauntStandEffectHelper()
      {
         super();
      }
      
      public static function setStandStatus(param1:Sprite, param2:int, param3:PetBriefInfo, param4:Number, param5:Number) : void
      {
         var fightFlauntResArr:*;
         var hasState:Boolean;
         var key:String = null;
         var layer:Sprite = param1;
         var locaId:int = param2;
         var thePet:PetBriefInfo = param3;
         var x:Number = param4;
         var y:Number = param5;
         var raceId:int = int(thePet.raceId);
         var face:int = getFace(locaId);
         key = KEY_STAND + "_" + locaId + "_" + face;
         var hasView:Boolean = layer.getChildByName(key) != null;
         var playerInfo:PlayerBattleInfo = FightData.instance.playerInfo[FightData.instance.getSlotId(locaId)];
         if(playerInfo == null)
         {
            return;
         }
         fightFlauntResArr = (playerInfo.myPets[0] as PetBriefInfo).fightFlauntResArr;
         hasState = Boolean(fightFlauntResArr[2]) && fightFlauntResArr[2] != _ffrSvr.getDefaultFightFlauntResArr()[2];
         if(hasState && hasView)
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
         _ffrSvr.getFightFlauntResourceMovie(fightFlauntResArr[2],function(param1:MovieClip):void
         {
            param1.x = x;
            param1.y = y;
            param1.name = key;
            layer.addChild(param1);
         });
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
   }
}

