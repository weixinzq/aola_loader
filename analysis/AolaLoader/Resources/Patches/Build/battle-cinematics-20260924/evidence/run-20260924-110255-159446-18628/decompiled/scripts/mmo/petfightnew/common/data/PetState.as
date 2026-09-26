package mmo.petfightnew.common.data
{
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.petfightnew.common.util.StatusUtil;
   
   public class PetState
   {
      
      public static const NORMAL:int = 0;
      
      public static const CHANGING_VIEW:int = 1;
      
      public function PetState()
      {
         super();
      }
      
      public static function getPetState(param1:PetBriefInfo) : int
      {
         if(Boolean(param1.isChangingView()) || StatusUtil.isPetInLegendFieldState(param1))
         {
            return PetState.CHANGING_VIEW;
         }
         return PetState.NORMAL;
      }
   }
}

