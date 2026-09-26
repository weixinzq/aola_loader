package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.pm.services.IPMService;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2573")]
   public class HKPanel extends PetDetailBase
   {
      
      public var containerarea:MovieClip;
      
      private var isDisposed:Boolean = false;
      
      private var soulCardPanel:DisplayObject = null;
      
      private var area:Sprite = null;
      
      private var _isNew:Boolean = true;
      
      public function HKPanel()
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
         if(this.soulCardPanel != null)
         {
            this.soulCardPanel.visible = this.isCurSelectGuangQiPet();
         }
      }
      
      private function isCurSelectGuangQiPet() : Boolean
      {
         var _loc1_:IPMService = null;
         if(pdi)
         {
            _loc1_ = ServiceContainer.getService(IPMService) as IPMService;
            return _loc1_.getOperationPM(pdi.raceId).pmData.isGQPM();
         }
         return false;
      }
      
      override public function dispose() : void
      {
         super.dispose();
         this.isDisposed = true;
         if(this.soulCardPanel != null)
         {
            if(this.soulCardPanel.parent)
            {
               this.soulCardPanel.parent.removeChild(this.soulCardPanel);
            }
            IDispose(this.soulCardPanel).dispose();
            this.soulCardPanel = null;
         }
      }
   }
}

