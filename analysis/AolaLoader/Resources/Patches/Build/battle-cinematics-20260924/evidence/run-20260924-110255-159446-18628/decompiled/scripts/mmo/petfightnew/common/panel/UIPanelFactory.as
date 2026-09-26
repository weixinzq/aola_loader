package mmo.petfightnew.common.panel
{
   import mmo.petfightnew.common.panel.skill.NewSkillPanel;
   
   public class UIPanelFactory
   {
      
      public function UIPanelFactory()
      {
         super();
      }
      
      public static function getUIPanel(param1:int) : UIPanelBase
      {
         var _loc2_:UIPanelBase = null;
         switch(param1)
         {
            case UIPanelType.PET:
               _loc2_ = new PetBar();
               break;
            case UIPanelType.CATCH:
               _loc2_ = new CatchPanel();
               break;
            case UIPanelType.SKILL:
               _loc2_ = new NewSkillPanel();
               break;
            case UIPanelType.ITEM:
               _loc2_ = new ItemPanel();
         }
         _loc2_.type = param1;
         return _loc2_;
      }
   }
}

