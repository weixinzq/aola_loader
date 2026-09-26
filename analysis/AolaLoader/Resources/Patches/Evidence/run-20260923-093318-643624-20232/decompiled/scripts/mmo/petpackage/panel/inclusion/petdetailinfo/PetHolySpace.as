package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.ServiceNames;
   import mmo.interfaces.catalog.IBookClubService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PetHolySpaceConfig;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2419")]
   public class PetHolySpace extends PetDetailBase
   {
      
      private static const baseX:Number = 588;
      
      private static const baseY:Number = 130;
      
      public var btnWhat:SimpleButton;
      
      public var mcSkillDetail:MovieClip;
      
      public var mcSpaceDetail:MovieClip;
      
      private var holySpaceIcon:Sprite;
      
      private var holySkilIcon:Sprite;
      
      public function PetHolySpace()
      {
         super();
         this.canUpdateUI = true;
         this.addEventListener(MouseEvent.CLICK,this.onClick);
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.target.name as String;
         switch(_loc2_)
         {
            case "btnWhat":
               this.showYabiCatalog();
         }
      }
      
      private function showYabiCatalog() : void
      {
         ProgressFullSprite.show();
         ServiceContainer.instance.tryGetService(ServiceNames.HandBookService,function(param1:IBookClubService, param2:Object = null):void
         {
            ProgressFullSprite.close();
            param1.showPageBy2Index("book201004",9,1);
         });
      }
      
      override protected function refreshUI() : void
      {
         var _loc3_:Array = null;
         var _loc8_:int = 0;
         var _loc9_:TextField = null;
         var _loc10_:TextField = null;
         var _loc1_:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         var _loc2_:String = _loc1_.customData.pmDataMap.getPM(pdi.raceId).pmImmunities;
         var _loc4_:int = -1;
         if(_loc2_ != "-1")
         {
            _loc3_ = _loc2_.split("#");
            _loc8_ = 0;
            while(_loc8_ < _loc3_.length)
            {
               if(PetHolySpaceConfig.isHolySpace(parseInt(_loc3_[_loc8_])))
               {
                  _loc4_ = parseInt(_loc3_[_loc8_]);
                  break;
               }
               _loc8_++;
            }
         }
         _loc2_ = _loc1_.customData.pmDataMap.getPM(pdi.raceId).pmHolySpaceInfo;
         var _loc5_:int = -1;
         if(_loc2_ != "")
         {
            _loc3_ = _loc2_.split("-");
            if(PetHolySpaceConfig.isHolySkill(parseInt(_loc3_[1])))
            {
               _loc5_ = parseInt(_loc3_[1]);
            }
         }
         var _loc6_:MovieClip = this.getChildByName("mcSpaceDetail") as MovieClip;
         if(_loc4_ == -1)
         {
            _loc6_.gotoAndStop(1);
         }
         else
         {
            _loc6_.gotoAndStop(2);
            _loc9_ = _loc6_.getChildByName("txtHolySpaceDes") as TextField;
            _loc9_.mouseEnabled = false;
            _loc9_.text = PetHolySpaceConfig.getDesById(_loc4_);
         }
         var _loc7_:MovieClip = this.getChildByName("mcSkillDetail") as MovieClip;
         if(_loc5_ == -1)
         {
            _loc7_.gotoAndStop(1);
         }
         else
         {
            _loc7_.gotoAndStop(2);
            _loc10_ = _loc7_.getChildByName("txtHolySkillDes") as TextField;
            _loc10_.mouseEnabled = false;
            _loc10_.text = PetHolySpaceConfig.getDesById(_loc5_);
         }
         this.showHolySpace(_loc4_);
         this.showHolySkill(_loc5_,pdi);
      }
      
      private function showHolySpace(param1:int) : void
      {
         var holySpaceId:int = param1;
         if(holySpaceId == -1)
         {
            DisplayUtil.stopAndRemove(this.holySpaceIcon);
            this.holySpaceIcon = null;
            return;
         }
         this.loadHolyRes(holySpaceId,function(param1:Sprite):void
         {
            DisplayUtil.stopAndRemove(holySpaceIcon);
            holySpaceIcon = param1;
            addChild(param1);
            param1.x = baseX;
            param1.y = baseY;
         });
      }
      
      private function showHolySkill(param1:int, param2:PetBriefInfo) : void
      {
         var i:int;
         var haveHolySkill:Boolean = false;
         var skillId:int = 0;
         var holySkillId:int = param1;
         var pbi:PetBriefInfo = param2;
         if(holySkillId == -1)
         {
            DisplayUtil.stopAndRemove(this.holySkilIcon);
            this.holySkilIcon = null;
            return;
         }
         haveHolySkill = false;
         i = 0;
         while(i < pbi.specialAbilityArr.length)
         {
            skillId = int(pbi.specialAbilityArr[i]);
            if(PetHolySpaceConfig.isHolySkill(skillId))
            {
               haveHolySkill = true;
               break;
            }
            i++;
         }
         this.loadHolyRes(holySkillId,function(param1:Sprite):void
         {
            DisplayUtil.stopAndRemove(holySkilIcon);
            holySkilIcon = param1;
            var _loc2_:Sprite = holySkilIcon.getChildByName("spHandle") as Sprite;
            if(_loc2_ != null)
            {
               _loc2_.visible = !haveHolySkill;
            }
            addChild(param1);
            param1.x = baseX;
            param1.y = baseY;
         });
      }
      
      private function loadHolyRes(param1:int, param2:Function) : void
      {
         var id:int = param1;
         var callBack:Function = param2;
         ResScheduler.getRes(ResParams.createTemp("pet/holyspace/holyspaceres_" + id.toString(),function(param1:Sprite, param2:ApplicationDomain = null):void
         {
            callBack.apply(null,[param1]);
         },"mmo.petpackage.HolySpaceRes_" + id.toString(),ResPriority.NORMAL,function():void
         {
         }));
      }
      
      override public function dispose() : void
      {
         this.removeEventListener(MouseEvent.CLICK,this.onClick);
         super.dispose();
      }
   }
}

