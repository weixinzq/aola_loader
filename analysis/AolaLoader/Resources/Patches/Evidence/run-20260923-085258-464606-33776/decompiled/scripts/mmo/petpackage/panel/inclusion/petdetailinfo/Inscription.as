package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.pm.services.IPMService;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2827")]
   public class Inscription extends PetDetailBase
   {
      
      public var containerarea:MovieClip;
      
      private var isDisposed:Boolean = false;
      
      private var inscriptionPanel:DisplayObject = null;
      
      private var area:Sprite = null;
      
      public function Inscription()
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
         if(this.inscriptionPanel != null)
         {
            this.inscriptionPanel.visible = this.isCurSelectDegeneratorPet();
         }
      }
      
      private function isCurSelectDegeneratorPet() : Boolean
      {
         var _loc1_:IPMService = null;
         if(pdi)
         {
            _loc1_ = ServiceContainer.getService(IPMService) as IPMService;
            return _loc1_.getOperationPM(pdi.raceId).pmData.isDegeneratorPM();
         }
         return false;
      }
      
      override public function dispose() : void
      {
         this.isDisposed = true;
         if(null != this.inscriptionPanel)
         {
            IDispose(this.inscriptionPanel).dispose();
            this.inscriptionPanel = null;
         }
      }
   }
}

