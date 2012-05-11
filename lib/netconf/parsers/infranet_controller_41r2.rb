require 'set'

module InfranetController41r2
  def self.object_paths
    {
      :role => 'configuration/users/user-roles/user-role',
      :ipsec_policy => 'configuration/uac/infranet-enforcer/ipsec-routing-policies/ipsec-routing-policy',
      :resource_policy => 'configuration/uac/infranet-enforcer/resource-access-policies/resource-access-policy',
      :address_pool => 'configuration/uac/infranet-enforcer/ip-address-pools-policies/ip-address-pools-policy',
      :auth_table => 'configuration/uac/infranet-enforcer/auth-table-mapping-policies/auth-table-mapping-policy',
      :realm => 'configuration/users/user-realms/realm',
    }
  end

  def self.has_capability? cap
    cap =~ /http:\/\/xml.juniper.net\/dmi\/ive-ic\/4.1R2/ ||
    cap =~ /http:\/\/xml.juniper.net\/dmi\/ive-ic\/4.1R5/ ||
    cap =~ /http:\/\/xml.juniper.net\/dmi\/ive-ic\/4.1R7/
  end

  def edit_role name, attributes={}, &block
    edit_object(InfranetController41r2.object_paths[:role], name, attributes, &block)
  end

  def edit_resource name, attributes={}, &block
    edit_object(InfranetController41r2.object_paths[:resource_policy], name, attributes, &block)
  end

  def edit_ipsec_policy name, attributes={}, &block
    edit_object(InfranetController41r2.object_paths[:ipsec_policy], name, attributes, &block)
  end

  def new_role name, description
    edit_role(name, 'operation' => 'create') do |xml|
      xml.general do
        xml.overview do
          xml.description description
        end
      end
    end
  end

  def change_role_name old_name, new_name
    edit_role(old_name, 'rename' => 'rename', 'name' => new_name)
  end

  def change_role_description name, description
    edit_role(name) do |xml|
      xml.general do
        xml.overview do
          xml.description description
        end
      end
    end
  end

  def delete_role name
    edit_role(name, 'operation' => 'delete')
  end

  def add_role_to_mapping realm_name, mapping, role_name, user_names=[]
    roles = get_mapping_roles(realm_name, mapping)
    roles << role_name
    set_mapping_roles(realm_name, mapping, roles, user_names)
  end

  def remove_role_from_mapping realm_name, mapping, role_name, user_names=[]
    roles = get_mapping_roles(realm_name, mapping)
    roles.delete(role_name)
    set_mapping_roles(realm_name, mapping, roles, user_names)
  end

  def new_resource name, description
    edit_resource(name, 'operation' => 'create') do |xml|
      xml.description description
      xml.action 'deny-access'
      xml.apply 'selected-roles'
      xml.resources '0.0.0.0/0'
    end
  end

  def change_resource_name old_name, new_name
    edit_resource(old_name, 'rename' => 'rename', 'name' => new_name)
  end

  def change_resource_description name, description
    edit_resource(name) do |xml|
      xml.description description
    end
  end

  def set_resource_access name, access
    edit_resource(name, 'operation' => 'create') do |xml|
      xml.action 'allow-access'
      xml.resources access
    end
  end

  def add_role_to_resource resource_name, role_name
    roles = get_resource_roles(resource_name)
    roles << role_name
    set_resource_roles(resource_name, roles)
  end

  def remove_role_from_resource resource_name, role_name
    roles = get_resource_roles(resource_name)
    roles.delete(role_name)
    set_resource_roles(resource_name, roles)
  end

  def delete_resource name
    edit_resource(name, 'operation' => 'delete')
  end

  def new_ipsec_policy name, description, routes, exceptions=[]
    edit_ipsec_policy(name, 'operation' => 'create') do |xml|
      xml.description description
      xml.manual do
        routes.each do |route|
          xml.resources route
        end
        exceptions.each do |exception|
          xml.tag!('exception-to-resource', exception)
        end
      end
      xml.apply('selected-roles')
    end
  end

  def change_ipsec_policy_description name, description
    edit_ipsec_policy(name) do |xml|
      xml.description description
    end
  end

  def set_ipsec_policy_routes name, routes
    edit_ipsec_policy(name) do |xml|
      xml.manual do
        routes.each do |route|
          xml.resources route
        end
      end
    end
  end

  def set_ipsec_policy_exceptions name, exceptions
    edit_ipsec_policy(name) do |xml|
      xml.manual do
        exceptions.each do |exception|
          xml.tag!('exception-to-resource', exception)
        end
      end
    end
  end

  def add_role_to_ipsec_policy ipsec_policy, role_name
    roles = get_ipsec_policy_roles(ipsec_policy)
    roles << role_name
    set_ipsec_policy_roles(resource_name, roles)
  end

  def remove_role_from_ipsec_policy ipsec_policy, role_name
    roles = get_ipsec_policy_roles(ipsec_policy)
    roles.delete(role_name)
    set_ipsec_policy_roles(resource_name, roles)
  end

  def set_ipsec_policy_roles name, roles
    set_object_roles(InfranetController41r2.object_paths[:ipsec_policy], name, roles)
  end

  def set_auth_table_roles name, roles
    set_object_roles(InfranetController41r2.object_paths[:auth_table], name, roles)
  end

  def set_address_pool_roles name, roles
    set_object_roles(InfranetController41r2.object_paths[:address_pool], name, roles)
  end

  def set_resource_roles name, roles
    set_object_roles(InfranetController41r2.object_paths[:resource_policy], name, roles)
  end

  def get_auth_table_roles auth_table
    get_roles_for_object(InfranetController41r2.object_paths[:auth_table], auth_table)
  end

  def get_address_pool_roles address_pool
    get_roles_for_object(InfranetController41r2.object_paths[:address_pool], address_pool)
  end

  def get_resource_roles resource_name
    get_roles_for_object(InfranetController41r2.object_paths[:resource_policy], resource_name)
  end

  def get_ipsec_policy_roles ipsec_policy_name
    get_roles_for_object(InfranetController41r2.object_paths[:ipsec_policy], ipsec_policy_name)
  end

  def get_role_auth_tables role_name
    get_objects_for_role(InfranetController41r2.object_paths[:auth_table], role_name)
  end

  def get_role_address_pools role_name
    get_objects_for_role(InfranetController41r2.object_paths[:address_pool], role_name)
  end

  def get_role_ipsec_policies role_name
    get_objects_for_role(InfranetController41r2.object_paths[:ipsec_policy], role_name)
  end

  def get_role_resources role_name
    get_objects_for_role(InfranetController41r2.object_paths[:resource_policy], role_name)
  end

  def get_realms
    get_objects(InfranetController41r2.object_paths[:realm], 'name')
  end

  def set_mapping_roles realm_name, mapping, roles, user_names=[]
    edit_config('running') do |xml|
      build(xml, "configuration/users/user-realms/realm") do |xml|
        xml.name realm_name
        if (roles.size > 0)
          build(xml, 'role-mapping-rules/rule') do 
            xml.name mapping, 'operation' => 'merge'
            if (user_names.size > 0)
              xml.tag!('user-name') do
                xml.test 'is'
                user_names.each do |user_name|
                  xml.tag!('user-names', user_name)
                end
              end
            end
            roles.each do |role|
              xml.roles role
            end
          end
        else
          build(xml, 'role-mapping-rules') do 
            xml.rule('operation' => 'delete') do 
              xml.name mapping
            end
          end
        end
      end
    end
  end

  def get_role_mappings role_name=nil
    mappings = {}
    get_realms.each do |realm_name|
      mappings[realm_name] = {}
      xml_string = build_xml('configuration/users/user-realms/realm') do |xml|
        xml.name realm_name
        build(xml, 'role-mapping-rules/rule') do
          xml.name
          xml.roles
        end
      end
      get_object('configuration/users/user-realms/realm/role-mapping-rules/rule', '', [], xml_string) do |reader|
        name = ""
        roles = Set.new
        while (reader.read)
          break if (reader.name == 'rule')
          next if (reader.node_type == XML::Reader::TYPE_END_ELEMENT)
          name = reader.read_string if (reader.name == 'name')
          if (reader.name == 'roles')
            matched_name = reader.read_string
            if (! matched_name.empty? && (role_name.nil? || role_name == matched_name))
              roles << matched_name
            end
          end
        end
        if (role_name.nil? || roles.size > 0)
          mappings[realm_name][name] = roles
        end
      end
    end
    mappings
  end

  def get_mapping_roles realm_name, mapping
    xml_string = build_xml('configuration/users/user-realms/realm') do |xml|
      xml.name realm_name
      build(xml, 'role-mapping-rules/rule') do 
        xml.name mapping
      end
    end
    roles = Set.new
    get_object('configuration/users/user-realms/realm/role-mapping-rules/rule', realm_name, [], xml_string) do |reader|
      while(reader.read)
        break if (reader.name == 'rule')
        next if (reader.node_type == XML::Reader::TYPE_END_ELEMENT)
        if (reader.name == 'roles')
          role = reader.read_string
          roles << role unless (role.empty?)
        end
      end
    end
    return roles
  end

  private
    def edit_object object_path, name, attributes={}, &block
      object_path = object_path.split(/\//)
      object_tag = object_path.pop
      object_path = object_path.join('/')

      if (attributes['rename'].nil?)
        attributes['operation'] ||= 'merge'
      end

      edit_config('running') do |xml|
        build(xml, object_path) do
          xml.tag!(object_tag, attributes) do
            xml.name name
            block.call xml unless(block.nil?)
          end
        end
      end
    end

    def set_object_roles object_path, object_name, roles
      edit_object(object_path, object_name, 'operation' => 'merge') do |xml|
        if roles.size > 0
          roles.each do |role|
            xml.roles role
          end 
        else
          xml.roles
        end
      end
    end

    def get_objects object_path, match_element, object_name='', &block
      objects = Set.new
      object_tag = object_path.split(/\//)
      object_tag = object_tag.last
      get_object(object_path, object_name, ['name', match_element]) do |reader|
        matched = false
        while (reader.read)
          break if (reader.name == object_tag)
          next if (reader.node_type == XML::Reader::TYPE_END_ELEMENT)
          name = reader.read_string if (reader.name == 'name')
          if (reader.name == match_element)
            object = reader.read_string
            unless (block.nil?)
              object = block.call(name, object)
            end
            objects << object unless (object.nil? || object.empty?)
          end
        end
      end
      return objects
    end

    def get_objects_for_role object_path, role_name
      get_objects(object_path, 'roles') do |object_name, matched_role|
        object_name if (role_name == matched_role)
      end
    end

    def get_roles_for_object object_path, object_name
      get_objects(object_path, 'roles', object_name)
    end

    def build_xml path, &block
      target = ""
      xml = Builder::XmlMarkup.new(:target => target, :indent => 1)
      build(xml, path, &block)
      target
    end

    def build xml, path, &block
      path = path.split(/\//) if (path.is_a? String)
      while true do
        if (path.length == 0)
          block.call xml
          return
        end
        element = path.shift
        unless (element.nil? || element == '')
          xml.tag! element do
            build xml, path, &block
          end
          return
        end
      end
      target
    end
 
    def get_object path, name, selectors=[], xml=nil, &block
      object = nil
      if (xml.nil?)
        xml = build_xml(path) do |xml|
          xml.name name unless (name == '')
          selectors.each do |selector|
            xml.tag! selector
          end
        end
      end

      path = path.split(/\//)
      current_path = []
      config = get_config('running', xml) do |reader|
        while (reader.read)
          break if (reader.name == 'data')
          current_path.push(reader.name) if (reader.node_type == XML::Reader::TYPE_ELEMENT)
          current_path.pop if (reader.node_type == XML::Reader::TYPE_END_ELEMENT)
          if (current_path == path)
            if (block.nil?)
              object =  XML::Document.string(reader.read_outer_xml)
            else
              block.call(reader)
            end
            current_path.pop
          end
        end
      end
      return object
    end
end
