package mmo.petpackage.panel.inclusion
{
   import flash.display.MovieClip;
   import flash.text.TextField;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.services.IPMService;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol321")]
   public class XinghuiQiyuanTipsPanel extends MovieClip
   {
      
      public var mcattr:MovieClip;
      
      private var _pmSvr:IPMService = ServiceContainer.getService(IPMService) as IPMService;
      
      private var _raceId:int;
      
      public function XinghuiQiyuanTipsPanel(param1:int)
      {
         super();
         this._raceId = param1;
         this.init();
      }
      
      private function init() : void
      {
         var _loc1_:PMData = this._pmSvr.getOperationPM(this._raceId).pmData;
         this.mcattr.gotoAndStop(_loc1_.pmAttribute - 22);
         (this.mcattr.txtname as TextField).text = _loc1_.pmName;
      }
   }
}

