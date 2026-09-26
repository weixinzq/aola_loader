package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.pm.services.IPMService;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2572")]
   public class TotePanel extends PetDetailBase
   {
      
      public var containerarea:MovieClip;
      
      private var isDisposed:Boolean = false;
      
      private var totePanel:DisplayObject = null;
      
      private var area:Sprite = null;
      
      public function TotePanel()
      {
         super();
         this.area = this.containerarea as Sprite;
         this.area.visible = false;
      }
      
      override protected function initUI() : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      override protected function refreshUI() : void
      {
         if(this.totePanel != null)
         {
            this.totePanel.visible = this.isCurSelectGuangQiPet();
         }
      }
      
      private function isCurSelectGuangQiPet() : Boolean
      {
         var _loc1_:IPMService = null;
         if(pdi)
         {
            _loc1_ = ServiceContainer.getService(IPMService) as IPMService;
            return Boolean(_loc1_.getOperationPM(pdi.raceId).pmData.isGQPM()) && pdi.usingGQSkillType == 1;
         }
         return false;
      }
      
      override public function dispose() : void
      {
         super.dispose();
         this.isDisposed = true;
         if(this.totePanel != null)
         {
            if(this.totePanel.parent)
            {
               this.totePanel.parent.removeChild(this.totePanel);
            }
            IDispose(this.totePanel).dispose();
            this.totePanel = null;
         }
      }
   }
}

