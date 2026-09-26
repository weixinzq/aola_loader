package mmo.petfightnew.common.fightcontroller.fightinfopanel.tab
{
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.common.FIP_Info;
   
   public class FIP_TabFactory
   {
      
      public function FIP_TabFactory()
      {
         super();
      }
      
      public static function getTab(param1:FIP_Info, param2:int, param3:Function) : FIP_TabBase
      {
         var _loc4_:FIP_TabBase = null;
         switch(param2)
         {
            case FIP_TabId.DETAIL:
               _loc4_ = new FIP_Tab0(param1,param2,param3);
               break;
            case FIP_TabId.SKILL:
               _loc4_ = new FIP_Tab1(param1,param2,param3);
               break;
            case FIP_TabId.STATE:
               _loc4_ = new FIP_Tab2(param1,param2,param3);
               break;
            case FIP_TabId.TRAIN:
               _loc4_ = new FIP_Tab3(param1,param2,param3);
               break;
            case FIP_TabId.NOGQPM:
               _loc4_ = new FIP_Tab4(param1,param2,param3);
         }
         return _loc4_;
      }
   }
}

