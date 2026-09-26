package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.MovieClip;
   import flash.text.TextField;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.petcommon.GeniusHelper;
   import mmo.interfaces.pet.pm.operation.Ability;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.play.activity.helper.Pet_Helper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2790")]
   public class PetGeniusDetail extends MovieClip
   {
      
      public var giftIcon:MovieClip;
      
      public var mcgeniusname:MovieClip;
      
      public var mcrecomm_0:MovieClip;
      
      public var mcrecomm_1:MovieClip;
      
      public var mcrecomm_2:MovieClip;
      
      public var mcrecomm_3:MovieClip;
      
      public var mcrecomm_4:MovieClip;
      
      public var mcrecomm_5:MovieClip;
      
      public var num0:TextField;
      
      public var num1:TextField;
      
      public var num2:TextField;
      
      public var num3:TextField;
      
      public var num4:TextField;
      
      public var num5:TextField;
      
      public var s0:MovieClip;
      
      public var s1:MovieClip;
      
      public var s2:MovieClip;
      
      public var s3:MovieClip;
      
      public var s4:MovieClip;
      
      public var s5:MovieClip;
      
      public var starNumTxt:TextField;
      
      private const GENIUS_NUM:int = 6;
      
      public function PetGeniusDetail()
      {
         super();
         this.mouseEnabled = false;
         this.mouseChildren = false;
      }
      
      public function setInfo(param1:PetBriefInfo) : void
      {
         this.updateStars([this.s0,this.s1,this.s2,this.s3,this.s4,this.s5],param1);
         this.updateValues([this.num0,this.num1,this.num2,this.num3,this.num4,this.num5],param1);
         this.handleRecommends(param1);
         var _loc2_:* = GeniusHelper.getGeniusFrameIndex(param1.ind.arrayData);
         this.mcgeniusname.gotoAndStop(_loc2_);
         this.giftIcon.gotoAndStop(_loc2_);
      }
      
      private function updateStars(param1:Array, param2:PetBriefInfo) : void
      {
         var _loc4_:int = 0;
         var _loc3_:int = 0;
         while(_loc3_ < param1.length)
         {
            _loc4_ = int(GeniusHelper.getStarNumber(param2.ind.getValueByIndex(_loc3_),Pet_Helper.checkPetIsGQPet(param2.raceId)));
            MovieClip(param1[_loc3_]).gotoAndStop(_loc4_ + 1);
            _loc3_++;
         }
      }
      
      private function handleRecommends(param1:PetBriefInfo) : void
      {
         var _loc5_:Ability = null;
         var _loc6_:MovieClip = null;
         var _loc7_:int = 0;
         var _loc2_:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         var _loc3_:Vector.<Ability> = _loc2_.getOperationPM(param1.raceId).getRecommendAbility();
         var _loc4_:Array = [];
         for each(_loc5_ in _loc3_)
         {
            _loc4_.push(_loc5_.ability);
         }
         _loc7_ = 0;
         while(_loc7_ < this.GENIUS_NUM)
         {
            _loc6_ = this.getChildByName("mcrecomm_" + _loc7_) as MovieClip;
            _loc6_.visible = _loc4_.indexOf(_loc7_) != -1;
            _loc7_++;
         }
      }
      
      private function updateValues(param1:Array, param2:PetBriefInfo) : void
      {
         var _loc5_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         while(_loc4_ < param1.length)
         {
            _loc5_ = int(param2.ind.getValueByIndex(_loc4_));
            _loc3_ += _loc5_;
            TextField(param1[_loc4_]).text = _loc5_ + "";
            _loc4_++;
         }
         this.starNumTxt.text = _loc3_.toString();
      }
   }
}

