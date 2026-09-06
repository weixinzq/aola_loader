package mmo.petfightnew.common.data
{
   import mmo.interfaces.legend.LegendPetType;
   import mmo.interfaces.miraclepet.IMiraclePetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class PetType
   {
      
      public static const NORMAL:int = 0;
      
      public static const MIRACLE:int = 1;
      
      public static const COMPLETED:int = 2;
      
      public static const GOT_SKILL_AOYI:int = 3;
      
      public static const KILL_LEGEND:int = 4;
      
      public static const FIELD_LEGEND:int = 5;
      
      public static const TOTEM_LEGEND:int = 6;
      
      public static const DEGENERATOR:int = 7;
      
      public static const XINGHUI:int = 8;
      
      public static const GQ:int = 9;
      
      public function PetType()
      {
         super();
      }
      
      public static function isLegendPet(param1:int) : Boolean
      {
         return param1 == KILL_LEGEND || param1 == FIELD_LEGEND || param1 == TOTEM_LEGEND;
      }
      
      public static function isDegeneratorPet(param1:int) : Boolean
      {
         return param1 == DEGENERATOR;
      }
      
      public static function isXinghuiPet(param1:int) : Boolean
      {
         return param1 == XINGHUI;
      }
      
      public static function isGQPet(param1:int) : Boolean
      {
         return param1 == GQ;
      }
      
      public static function getPetType(param1:PetBriefInfo) : int
      {
         var _loc2_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc3_:IMiraclePetDataService = ServicePool.instance.getService(IMiraclePetDataService);
         var _loc4_:PMData = _loc2_.getOperationPM(param1.raceId).pmData;
         var _loc5_:int = PetType.NORMAL;
         if(param1.isGetAoYiSkill)
         {
            _loc5_ = PetType.GOT_SKILL_AOYI;
         }
         else if(_loc3_.getMiraclePetInfo(param1.raceId) != null)
         {
            _loc5_ = PetType.MIRACLE;
         }
         else if(_loc4_.isCompletePM())
         {
            _loc5_ = PetType.COMPLETED;
         }
         else if(_loc4_.isLegendPM())
         {
            switch(_loc4_.getLegendType())
            {
               case LegendPetType.KILL:
                  _loc5_ = PetType.KILL_LEGEND;
                  break;
               case LegendPetType.FIELD:
                  _loc5_ = PetType.FIELD_LEGEND;
                  break;
               case LegendPetType.TOTEM:
                  _loc5_ = PetType.TOTEM_LEGEND;
            }
         }
         else if(_loc4_.isDegeneratorPM())
         {
            _loc5_ = PetType.DEGENERATOR;
         }
         else if(_loc4_.isXinghuiPM())
         {
            _loc5_ = PetType.XINGHUI;
         }
         else if(_loc4_.isGQPM())
         {
            _loc5_ = PetType.GQ;
         }
         return _loc5_;
      }
   }
}

