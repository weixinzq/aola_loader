package mmo.petpackage.controller.helper
{
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   
   public class TabJumpHelper
   {
      
      public function TabJumpHelper()
      {
         super();
      }
      
      public static function changeFirstTab(param1:int) : void
      {
         PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_JUMP_FIRST_TAB,{"index":param1}));
      }
      
      public static function changeSecondTab(param1:int) : void
      {
         PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_JUMP_SECOND_TAB,{"index":param1}));
      }
   }
}

