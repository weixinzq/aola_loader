package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.text.TextField;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.PetDetailedInfo;
   import mmo.interfaces.pet.pm.operation.Ability;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petpackage.controller.helper.AddPetDetailInfoHelper;
   import mmo.util.component.artnumber.ArtNumberManager;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2641")]
   public class PetStudyInfo extends PetDetailBase
   {
      
      public var btnOpenStudy:SimpleButton;
      
      public var mcl0:MovieClip;
      
      public var mcl1:MovieClip;
      
      public var mcl2:MovieClip;
      
      public var mcstudy_0:MovieClip;
      
      public var mcstudy_1:MovieClip;
      
      public var mcstudy_2:MovieClip;
      
      public var meffrec_0:MovieClip;
      
      public var meffrec_1:MovieClip;
      
      public var meffrec_2:MovieClip;
      
      public var meffrec_3:MovieClip;
      
      public var meffrec_4:MovieClip;
      
      public var meffrec_5:MovieClip;
      
      public var txt_lattack:TextField;
      
      public var txt_ldefence:TextField;
      
      public var txt_lhp:TextField;
      
      public var txt_lsattack:TextField;
      
      public var txt_lsdefence:TextField;
      
      public var txt_lspeed:TextField;
      
      public function PetStudyInfo()
      {
         super();
      }
      
      override protected function initUI() : void
      {
         AddPetDetailInfoHelper.addDetailInfoMC(1,this,this.setCanUpdate);
      }
      
      override protected function refreshUI() : void
      {
         var _loc6_:Ability = null;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc1_:Array = this.getEffs(pdi);
         var _loc2_:Array = [this.txt_lhp,this.txt_lattack,this.txt_ldefence,this.txt_lsattack,this.txt_lsdefence,this.txt_lspeed];
         var _loc3_:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         var _loc4_:int = 0;
         while(_loc4_ < 6)
         {
            this.getChildByName("meffrec_" + _loc4_).visible = false;
            _loc4_++;
         }
         var _loc5_:Vector.<Ability> = _loc3_.getOperationPM(pdi.raceId).getRecommendAbility();
         for each(_loc6_ in _loc5_)
         {
            this.getChildByName("meffrec_" + _loc6_.ability).visible = true;
         }
         _loc7_ = 0;
         _loc8_ = 0;
         while(_loc8_ < _loc1_.length)
         {
            _loc2_[_loc8_].text = _loc1_[_loc8_] + "";
            _loc7_ += _loc1_[_loc8_];
            _loc8_++;
         }
         ArtNumberManager.setNumber([this.mcstudy_0,this.mcstudy_1,this.mcstudy_2],_loc7_);
      }
      
      private function getEffs(param1:PetDetailedInfo) : Array
      {
         if(null == param1)
         {
            return [0,0,0,0,0,0];
         }
         return param1.eff.arrayData;
      }
   }
}

