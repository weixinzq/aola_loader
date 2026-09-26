package mmo.petpackage.panel.inclusion
{
   import com.adobe.utils.ArrayUtil;
   import flash.display.Sprite;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.pm.operation.IPMSkillInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1267")]
   public class CompleteMiraclePMAllSkillComponent extends Sprite
   {
      
      public var mpsc0:CompleteMiraclePMSkillComponent;
      
      public var mpsc1:CompleteMiraclePMSkillComponent;
      
      public var mpsc2:CompleteMiraclePMSkillComponent;
      
      public function CompleteMiraclePMAllSkillComponent()
      {
         super();
      }
      
      public function refresh(param1:int, param2:Array) : void
      {
         var _loc5_:CompleteMiraclePMSkillComponent = null;
         param2 = this.orderSkill(param1,param2);
         var _loc3_:Array = this.addPassiveSkill(param1,param2);
         var _loc4_:int = 0;
         while(_loc4_ < 3)
         {
            _loc5_ = this.getChildByName("mpsc" + _loc4_) as CompleteMiraclePMSkillComponent;
            _loc5_.refresh(_loc4_,_loc3_[_loc4_],_loc4_ == 2);
            _loc4_++;
         }
      }
      
      private function orderSkill(param1:int, param2:Array) : Array
      {
         var _loc6_:IPMSkillInfo = null;
         var _loc7_:int = 0;
         var _loc3_:Array = [];
         var _loc4_:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         var _loc5_:Vector.<IPMSkillInfo> = _loc4_.getOperationPM(param1).getCommonSkillList();
         for each(_loc6_ in _loc5_)
         {
            _loc7_ = 0;
            while(_loc7_ < param2.length)
            {
               if(_loc6_.skillId == (param2[_loc7_] as SkillInfo).id)
               {
                  _loc3_.push(param2[_loc7_]);
               }
               _loc7_++;
            }
         }
         return _loc3_;
      }
      
      private function addPassiveSkill(param1:*, param2:Array) : Array
      {
         var _loc3_:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         var _loc4_:int = int(_loc3_.getCompleteMiraclePMData(param1).skillId);
         var _loc5_:String = _loc3_.customData.pmSkillMap.getSkill(_loc4_).cnName;
         var _loc6_:SkillInfo = new SkillInfo();
         _loc6_.parseInfo({
            "pp":"0/0",
            "ssi":2,
            "used":true,
            "id":_loc4_,
            "name":_loc5_
         });
         var _loc7_:Array = ArrayUtil.copyArray(param2);
         _loc7_.push(_loc6_);
         return _loc7_;
      }
      
      public function dispose() : void
      {
         var _loc2_:CompleteMiraclePMSkillComponent = null;
         var _loc1_:int = 0;
         while(_loc1_ < 3)
         {
            _loc2_ = this.getChildByName("mpsc" + _loc1_) as CompleteMiraclePMSkillComponent;
            _loc2_.dispose();
            _loc1_++;
         }
      }
   }
}

