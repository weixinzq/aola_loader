package mmo.petpackage.controller.helper
{
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.petpackage.data.PetDetailDataMap;
   
   public class PetArrayRefresher
   {
      
      public function PetArrayRefresher()
      {
         super();
      }
      
      public static function updatePetsObj(param1:Array) : void
      {
         var _loc4_:Object = null;
         var _loc2_:PetBriefInfo = new PetBriefInfo();
         var _loc3_:int = 0;
         while(_loc3_ < param1.length)
         {
            _loc2_.parseInfo(param1[_loc3_]);
            if(PetDetailDataMap.instance.checkCache(_loc2_.id))
            {
               _loc4_ = PetDetailDataMap.instance.getPetInfo(_loc2_.id);
               param1[_loc3_].pmSView.nick = _loc4_.pmPView.nick;
               param1[_loc3_].pmSView.lv = _loc4_.pmPView.lv;
               param1[_loc3_].pmSView.c0 = _loc4_.pmPView.c0;
               param1[_loc3_].pmSView.s0 = _loc4_.pmPView.s0;
            }
            _loc3_++;
         }
      }
   }
}

