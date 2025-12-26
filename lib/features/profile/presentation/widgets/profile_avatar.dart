import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? name;
  final String? email;
  final double size;
  final VoidCallback? onTap;
  final bool editable;

  const ProfileAvatar({
    Key? key,
    this.photoUrl,
    this.name,
    this.email,
    this.size = 80,
    this.onTap,
    this.editable = false,
  }) : super(key: key);

  String get initials {
    if (name != null && name!.isNotEmpty) {
      return name!
          .split(' ')
          .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
          .join()
          .substring(0, 2)
          .toUpperCase();
    }
    if (email != null && email!.isNotEmpty) {
      return email!.substring(0, 2).toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            border: Border.all(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          child: photoUrl != null && photoUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(size / 2),
                  child: Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildInitialsAvatar(context);
                    },
                  ),
                )
              : _buildInitialsAvatar(context),
        ),
        if (editable)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: size * 0.35,
                height: size * 0.35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: size * 0.18,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInitialsAvatar(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
